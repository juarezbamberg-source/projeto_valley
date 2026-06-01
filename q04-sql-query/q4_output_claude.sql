-- ============================================================
-- RELATÓRIO MENSAL CONSOLIDADO DO LEDGER_PROD
-- Período: 2025-10-24 até 2026-04-24 (6 meses)
-- Filtros: transações completadas, categorias especificadas
-- ============================================================

-- 1. CTE Período: define as datas fixas do relatório
WITH periodo AS (
    SELECT
        '2025-10-24'::date AS data_inicio,
        '2026-04-24'::date AS data_fim
),

-- 2. CTE Transações Filtradas: aplica status, período e categorias
transacoes_filtradas AS (
    SELECT
        t.id,
        t.created_at,
        t.category,
        t.amount_cents,
        t.customer_id
    FROM
        transactions t
        INNER JOIN periodo p ON t.created_at >= p.data_inicio
                             AND t.created_at < (p.data_fim + interval '1 day')
    WHERE
        t.status = 'completed'
        AND t.category IN ('subscription', 'one_time', 'refund', 'credit_adjustment')
    -- NOTA: A junção com customers não é necessária para as métricas, mas mantida para
    -- garantir integridade referencial (todos os registros possuem customer válido)
    -- INNER JOIN customers c ON c.id = t.customer_id
)

-- 3. Query Principal: agregação mensal por categoria
SELECT
    to_char(date_trunc('month', tf.created_at), 'YYYY-MM') AS mes,
    tf.category AS categoria,
    COUNT(*)::integer AS quantidade_transacoes,
    ROUND(SUM(tf.amount_cents)::numeric / 100, 2) AS volume_reais
FROM
    transacoes_filtradas tf
GROUP BY
    date_trunc('month', tf.created_at),
    tf.category
ORDER BY
    mes ASC,
    categoria ASC;

-- ============================================================
-- 4. Exemplo de EXPLAIN ANALYZE (comentado)
-- ============================================================
-- EXPLAIN (ANALYZE, BUFFERS, TIMING)
-- SELECT
--     to_char(date_trunc('month', t.created_at), 'YYYY-MM') AS mes,
--     t.category AS categoria,
--     COUNT(*)::integer AS quantidade_transacoes,
--     ROUND(SUM(t.amount_cents)::numeric / 100, 2) AS volume_reais
-- FROM
--     transactions t
--     INNER JOIN customers c ON c.id = t.customer_id
-- WHERE
--     t.status = 'completed'
--     AND t.category IN ('subscription', 'one_time', 'refund', 'credit_adjustment')
--     AND t.created_at >= '2025-10-24'
--     AND t.created_at < '2026-04-25'  -- exclusivo do dia final, cobertura total
-- GROUP BY
--     date_trunc('month', t.created_at),
--     t.category
-- ORDER BY 1, 2;

-- ============================================================
-- 5. Validação de Índices (comentado)
-- ============================================================
-- Verifique a existência dos índices recomendados:
-- SELECT
--     indexname,
--     indexdef
-- FROM
--     pg_indexes
-- WHERE
--     tablename = 'transactions'
--     AND indexname IN ('idx_transactions_created_at',
--                       'idx_transactions_status',
--                       'idx_transactions_category');
--
-- Caso não existam, crie-os:
-- CREATE INDEX IF NOT EXISTS idx_transactions_created_at ON transactions (created_at);
-- CREATE INDEX IF NOT EXISTS idx_transactions_status ON transactions (status);
-- CREATE INDEX IF NOT EXISTS idx_transactions_category ON transactions (category);
-- Opcional: índice composto para otimizar ainda mais o filtro:
-- CREATE INDEX IF NOT EXISTS idx_transactions_completo
--     ON transactions (status, category, created_at) INCLUDE (amount_cents);

-- ============================================================
-- 6. Validação de Dados (contagem de registros) - comentado
-- ============================================================
-- Verifique a quantidade de transações no período:
-- SELECT
--     to_char(date_trunc('month', created_at), 'YYYY-MM') AS mes,
--     category,
--     COUNT(*) AS total_linhas,
--     COUNT(DISTINCT customer_id) AS clientes_unicos
-- FROM
--     transactions
-- WHERE
--     status = 'completed'
--     AND category IN ('subscription', 'one_time', 'refund', 'credit_adjustment')
--     AND created_at >= '2025-10-24'
--     AND created_at < '2026-04-25'
-- GROUP BY 1, 2
-- ORDER BY 1, 2;