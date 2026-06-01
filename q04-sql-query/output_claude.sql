-- ============================================================
-- Query: Relatório Analítico Mensal Consolidado - Ledger_Prod
-- Database: ledger_prod
-- Descrição: Agrega transações do último mês completo, calcula
-- estatísticas, identifica anomalias, top usuários e tendências.
-- ============================================================

-- ============================================================
-- 1. Criação de índices recomendados (se não existirem)
-- ============================================================
/*
CREATE INDEX IF NOT EXISTS idx_transactions_date_type
    ON transactions (created_at, type);

CREATE INDEX IF NOT EXISTS idx_transactions_user_account
    ON transactions (user_id, account_id);

CREATE INDEX IF NOT EXISTS idx_accounts_user_id
    ON accounts (user_id);

CREATE INDEX IF NOT EXISTS idx_users_id
    ON users (id);
*/

-- ============================================================
-- 2. Query principal com múltiplas CTEs
-- ============================================================
WITH
    -- ============================================================
    -- CTE 1: Parâmetros temporais dinâmicos (último mês completo)
    -- ============================================================
    periodo AS (
        SELECT
            date_trunc('month', CURRENT_DATE) - INTERVAL '1 month' AS inicio,
            date_trunc('month', CURRENT_DATE) - INTERVAL '1 day'   AS fim
    ),
    -- ============================================================
    -- CTE 2: Transações do período com dados de categoria (tipo)
    -- ============================================================
    transacoes_periodo AS (
        SELECT
            t.id,
            t.user_id,
            t.account_id,
            t.type,
            t.amount,
            t.status,            -- e.g., 'completed', 'failed', 'pending'
            t.created_at,
            u.name AS user_name,
            a.account_type       -- e.g., 'checking', 'savings'
        FROM transactions t
        JOIN accounts a ON a.id = t.account_id
        JOIN users u ON u.id = t.user_id
        CROSS JOIN periodo p
        WHERE t.created_at >= p.inicio
          AND t.created_at <= p.fim
    ),
    -- ============================================================
    -- CTE 3: Agregação por tipo de transação
    -- ============================================================
    agregacao_por_tipo AS (
        SELECT
            type,
            COUNT(*)                                           AS total_transacoes,
            SUM(amount)                                        AS valor_total,
            ROUND(AVG(amount)::numeric, 2)                     AS valor_medio,
            ROUND(STDDEV_POP(amount)::numeric, 2)              AS desvio_padrao,
            COUNT(*) FILTER (WHERE status = 'failed')          AS falhas,
            ROUND(COUNT(*) FILTER (WHERE status = 'failed') * 100.0 / NULLIF(COUNT(*), 0), 2) AS taxa_falha_percentual
        FROM transacoes_periodo
        GROUP BY type
    ),
    -- ============================================================
    -- CTE 4: Estatísticas gerais do período (médias e desvios)
    -- ============================================================
    estatisticas_gerais AS (
        SELECT
            ROUND(AVG(amount)::numeric, 2)                         AS media_geral,
            ROUND(STDDEV_POP(amount)::numeric, 2)                  AS desvio_geral,
            ROUND(AVG(amount)::numeric + 2 * STDDEV_POP(amount)::numeric, 2) AS limite_superior,
            ROUND(AVG(amount)::numeric - 2 * STDDEV_POP(amount)::numeric, 2) AS limite_inferior
        FROM transacoes_periodo
        WHERE amount IS NOT NULL
    ),
    -- ============================================================
    -- CTE 5: Identificação de anomalias (transações fora de 2 std)
    -- ============================================================
    anomalias AS (
        SELECT
            tp.id,
            tp.user_name,
            tp.type,
            tp.amount,
            tp.created_at,
            tp.status,
            CASE
                WHEN tp.amount < eg.limite_inferior OR tp.amount > eg.limite_superior
                    THEN 'Outlier (2σ)'
                ELSE 'Normal'
            END AS classificacao
        FROM transacoes_periodo tp
        CROSS JOIN estatisticas_gerais eg
        WHERE tp.amount IS NOT NULL
    ),
    -- ============================================================
    -- CTE 6: Transações com taxa de falha por usuário > 5%
    -- ============================================================
    falhas_por_usuario AS (
        SELECT
            user_id,
            user_name,
            COUNT(*)                                          AS total,
            COUNT(*) FILTER (WHERE status = 'failed')         AS falhas,
            ROUND(COUNT(*) FILTER (WHERE status = 'failed') * 100.0 / NULLIF(COUNT(*), 0), 2) AS taxa_falha
        FROM transacoes_periodo
        GROUP BY user_id, user_name
        HAVING COUNT(*) FILTER (WHERE status = 'failed') * 100.0 / NULLIF(COUNT(*), 0) > 5
    ),
    -- ============================================================
    -- CTE 7: Top 10 usuários por volume de transações (valor)
    -- ============================================================
    top_10_usuarios AS (
        SELECT
            user_id,
            user_name,
            COUNT(*)                                           AS total_transacoes,
            SUM(amount)                                        AS volume_total,
            ROUND(AVG(amount)::numeric, 2)                     AS valor_medio,
            ROW_NUMBER() OVER (ORDER BY SUM(amount) DESC)      AS rank_volume
        FROM transacoes_periodo
        GROUP BY user_id, user_name
        ORDER BY volume_total DESC
        LIMIT 10
    ),
    -- ============================================================
    -- CTE 8: Tendências diárias (agregação por dia)
    -- ============================================================
    tendencias_diarias AS (
        SELECT
            DATE(created_at)                            AS dia,
            COUNT(*)                                    AS total,
            SUM(amount)                                 AS valor_total,
            ROUND(AVG(amount)::numeric, 2)              AS valor_medio
        FROM transacoes_periodo
        GROUP BY DATE(created_at)
        ORDER BY dia
    ),
    -- ============================================================
    -- CTE 9: Tendências semanais (agregação por semana)
    -- ============================================================
    tendencias_semanais AS (
        SELECT
            DATE_TRUNC('week', created_at)::DATE        AS inicio_semana,
            COUNT(*)                                    AS total,
            SUM(amount)                                 AS valor_total,
            ROUND(AVG(amount)::numeric, 2)              AS valor_medio
        FROM transacoes_periodo
        GROUP BY DATE_TRUNC('week', created_at)
        ORDER BY inicio_semana
    )
-- ============================================================
-- Query final: retorna os resultados em formato estruturado (JSON)
-- ============================================================
SELECT
    jsonb_build_object(
        'periodo', jsonb_build_object(
            'inicio', (SELECT inicio FROM periodo),
            'fim',    (SELECT fim   FROM periodo)
        ),
        'agregacao_por_tipo', (SELECT jsonb_agg(row_to_json(t.*)) FROM agregacao_por_tipo t),
        'estatisticas_gerais', (SELECT row_to_json(e.*) FROM estatisticas_gerais e),
        'anomalias', (SELECT jsonb_agg(row_to_json(a.*)) FROM anomalias a WHERE a.classificacao = 'Outlier (2σ)'),
        'usuarios_com_taxa_falha_acima_5', (SELECT jsonb_agg(row_to_json(f.*)) FROM falhas_por_usuario f),
        'top_10_usuarios_por_volume', (SELECT jsonb_agg(row_to_json(t.*)) FROM top_10_usuarios t),
        'tendencias_diarias', (SELECT jsonb_agg(row_to_json(t.*)) FROM tendencias_diarias t),
        'tendencias_semanais', (SELECT jsonb_agg(row_to_json(t.*)) FROM tendencias_semanais t)
    ) AS relatorio_mensal;

-- ============================================================
-- 3. Exemplo de EXPLAIN ANALYZE (remova comentários para executar)
-- ============================================================
/*
EXPLAIN ANALYZE
WITH ... (mesma CTE acima)
SELECT ...;
*/

-- ============================================================
-- 4. Validação de índices existentes (auxiliar)
-- ============================================================
/*
SELECT schemaname, tablename, indexname, indexdef
FROM pg_indexes
WHERE tablename IN ('transactions', 'accounts', 'users')
ORDER BY tablename, indexname;
*/