-- Índice composto para o filtro de data (essencial para o particionamento lógico)
CREATE INDEX idx_transactions_created_at_type ON transactions(created_at, type);

-- Índices para otimizar os JOINs
CREATE INDEX idx_transactions_user_account ON transactions(user_id, account_id);
CREATE INDEX idx_accounts_user ON accounts(id, user_id);

-- Índice composto para acelerar o GROUP BY de agregação
CREATE INDEX idx_transactions_type_category_amount ON transactions(type, category, amount);


WITH 
-- Filtro dinâmico do último mês completo
last_month AS (
    SELECT 
        date_trunc('month', CURRENT_DATE - INTERVAL '1 month') AS start_date,
        date_trunc('month', CURRENT_DATE) - INTERVAL '1 day' AS end_date
),
-- Base de dados: transações do último mês completo
monthly_transactions AS (
    SELECT 
        t.id,
        t.user_id,
        t.account_id,
        t.type,
        t.category,
        t.amount,
        t.status,
        t.created_at,
        a.account_number,
        u.name AS user_name,
        u.email
    FROM transactions t
    JOIN accounts a ON t.account_id = a.id
    JOIN users u ON t.user_id = u.id
    WHERE t.created_at >= (SELECT start_date FROM last_month)
      AND t.created_at <= (SELECT end_date FROM last_month)
),
-- Agregações por tipo e categoria
agg_by_type_category AS (
    SELECT 
        type,
        category,
        COUNT(*) AS total_transactions,
        SUM(amount) AS total_amount,
        AVG(amount) AS avg_amount,
        STDDEV(amount) AS stddev_amount
    FROM monthly_transactions
    GROUP BY type, category
),
-- Identificação de anomalias: valores > 2 std dev por tipo/categoria
anomaly_amounts AS (
    SELECT mt.*
    FROM monthly_transactions mt
    JOIN agg_by_type_category a ON mt.type = a.type AND mt.category = a.category
    WHERE a.stddev_amount IS NOT NULL 
      AND ABS(mt.amount - a.avg_amount) > 2 * a.stddev_amount
),
-- Anomalias por alta taxa de falha (status = 'failed') por tipo/categoria
high_failure_rate AS (
    SELECT 
        type,
        category,
        COUNT(*) FILTER (WHERE status = 'failed') AS failed_count,
        COUNT(*) AS total_count,
        ROUND(100.0 * COUNT(*) FILTER (WHERE status = 'failed') / COUNT(*), 2) AS failure_rate_pct
    FROM monthly_transactions
    GROUP BY type, category
    HAVING ROUND(100.0 * COUNT(*) FILTER (WHERE status = 'failed') / COUNT(*), 2) > 20  -- threshold exemplo
),
-- Top 10 usuários por volume (soma de amounts)
top_users AS (
    SELECT 
        user_id,
        user_name,
        email,
        SUM(amount) AS total_volume,
        COUNT(*) AS transaction_count,
        DENSE_RANK() OVER (ORDER BY SUM(amount) DESC) AS rank
    FROM monthly_transactions
    GROUP BY user_id, user_name, email
    ORDER BY total_volume DESC
    LIMIT 10
),
-- Tendência diária
daily_trend AS (
    SELECT 
        DATE(created_at) AS day,
        COUNT(*) AS transactions,
        SUM(amount) AS volume
    FROM monthly_transactions
    GROUP BY DATE(created_at)
    ORDER BY day
),
-- Tendência semanal (ISO week)
weekly_trend AS (
    SELECT 
        DATE_TRUNC('week', created_at)::DATE AS week_start,
        COUNT(*) AS transactions,
        SUM(amount) AS volume
    FROM monthly_transactions
    GROUP BY week_start
    ORDER BY week_start
)
-- Consolidar tudo em um único JSON
SELECT json_build_object(
    'report_period', json_build_object(
        'start_date', (SELECT start_date FROM last_month),
        'end_date', (SELECT end_date FROM last_month)
    ),
    'aggregations_by_type_category', (
        SELECT json_agg(json_build_object(
            'type', type,
            'category', category,
            'total_transactions', total_transactions,
            'total_amount', total_amount,
            'avg_amount', avg_amount,
            'stddev_amount', stddev_amount
        )) FROM agg_by_type_category
    ),
    'anomalies', json_build_object(
        'amount_anomalies', (
            SELECT json_agg(json_build_object(
                'transaction_id', id,
                'user_id', user_id,
                'account_id', account_id,
                'type', type,
                'category', category,
                'amount', amount,
                'status', status
            )) FROM anomaly_amounts
        ),
        'high_failure_rate_categories', (
            SELECT json_agg(json_build_object(
                'type', type,
                'category', category,
                'failed_count', failed_count,
                'total_count', total_count,
                'failure_rate_pct', failure_rate_pct
            )) FROM high_failure_rate
        )
    ),
    'top_users_by_volume', (
        SELECT json_agg(json_build_object(
            'rank', rank,
            'user_id', user_id,
            'user_name', user_name,
            'email', email,
            'total_volume', total_volume,
            'transaction_count', transaction_count
        )) FROM top_users
    ),
    'daily_trends', (
        SELECT json_agg(json_build_object(
            'day', day,
            'transactions', transactions,
            'volume', volume
        )) FROM daily_trend
    ),
    'weekly_trends', (
        SELECT json_agg(json_build_object(
            'week_start', week_start,
            'transactions', transactions,
            'volume', volume
        )) FROM weekly_trend
    )
) AS monthly_report;

/*
 COMENTÁRIOS E CONSIDERAÇÕES DE PERFORMANCE:

 - A query utiliza CTEs para modularizar e facilitar a leitura/manutenção.
 - O filtro do último mês completo é dinâmico usando date_trunc e CURRENT_DATE.
 - As funções de agregação (SUM, AVG, STDDEV) e janela (DENSE_RANK) estão 
   aplicadas corretamente.
 - O resultado final é um único JSON estruturado via json_build_object e json_agg.
 - Recomenda-se a criação dos seguintes índices para performance:

   CREATE INDEX idx_transactions_created_at ON transactions(created_at);
   CREATE INDEX idx_transactions_type_category ON transactions(type, category);
   CREATE INDEX idx_transactions_user_id ON transactions(user_id);
   CREATE INDEX idx_transactions_account_id ON transactions(account_id);
   CREATE INDEX idx_accounts_id ON accounts(id);
   CREATE INDEX idx_users_id ON users(id);
   CREATE INDEX idx_users_name_email ON users(name, email);

 - Para grandes volumes, considere particionar a tabela transactions por data.
 - Se a tabela for enorme, substitua last_month por uma variável de sessão ou
   use materialized views para relatórios periódicos.
 - A detecção de anomalias pode ser ajustada (multiplique 2 por 1.5, 3 etc.).
 - O limiar de 20% para taxa de falha pode ser parametrizado.
*/