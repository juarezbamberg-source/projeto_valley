-- Relatório Financeiro para Jennifer (Executiva)
-- Objetivo: Quantidade e volume de transações finalizadas por mês e categoria,
-- considerando TODOS os clientes, no período de 2025-10-24 a 2026-04-24.
-- Banco: ledger_prod
-- Índices recomendados para produção:
--   idx_transactions_created_at (created_at)
--   idx_transactions_status     (status)
--   idx_transactions_category   (category)

-- CTE que traz apenas transações válidas para o relatório:
-- JOIN com customers para manter a relação, sem filtrar por nome de cliente.
WITH transacoes_validas AS (
    SELECT
        t.id              AS transacao_id,
        t.created_at      AS data_transacao,
        t.category        AS categoria,
        t.amount_cents    AS valor_centavos,
        c.id              AS cliente_id
    FROM transactions t
    INNER JOIN customers c
        ON t.customer_id = c.id
    WHERE t.status = 'completed'
      AND t.created_at >= '2025-10-24'
      AND t.created_at <  '2026-04-25'
      AND t.category IN (
            'subscription',
            'one_time',
            'refund',
            'credit_adjustment'
      )
)

-- Query principal: agrega transações por mês (YYYY-MM) e categoria.
SELECT
    TO_CHAR(data_transacao, 'YYYY-MM') AS mes,
    categoria                          AS categoria,
    COUNT(*)                           AS qtd_transacoes,
    ROUND(SUM(valor_centavos) / 100.00, 2) AS volume_reais
FROM transacoes_validas
GROUP BY
    TO_CHAR(data_transacao, 'YYYY-MM'),
    categoria
ORDER BY
    mes ASC,
    categoria ASC;