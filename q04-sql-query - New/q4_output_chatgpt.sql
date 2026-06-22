-- Relatório consolidado mensal de transações do ledger_prod
-- Período: últimos 6 meses corridos, de 2025-10-24 até 2026-04-24

-- CTE para filtrar transações completadas, nas categorias desejadas e no período
-- Os filtros são aplicados antes do JOIN para aproveitar os índices existentes
WITH transacoes_filtradas AS (
    SELECT
        t.customer_id,
        t.amount_cents,
        t.created_at,
        t.category
    FROM transactions t
    WHERE t.status = 'completed'
      AND t.category IN ('subscription', 'one_time', 'refund', 'credit_adjustment')
      AND t.created_at >= '2025-10-24'
      AND t.created_at <  '2026-04-25'
    -- Índices: idx_transactions_status, idx_transactions_category, idx_transactions_created_at
)

-- Agregação por mês e categoria, com JOIN na tabela de clientes
SELECT
    TO_CHAR(DATE_TRUNC('month', tf.created_at), 'YYYY-MM') AS mes,
    tf.category AS categoria,
    COUNT(*) AS qtd_transacoes,
    ROUND(SUM(tf.amount_cents) / 100.00, 2) AS volume_reais
FROM transacoes_filtradas tf
INNER JOIN customers c ON c.id = tf.customer_id
GROUP BY
    DATE_TRUNC('month', tf.created_at),
    tf.category
ORDER BY
    mes ASC,
    categoria ASC;