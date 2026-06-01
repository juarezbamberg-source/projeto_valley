-- ============================================================
-- Relatório mensal consolidado de transações (últimos 6 meses)
-- Período: 2025-10-24 a 2026-04-24
-- ============================================================

-- CTE: filtered_transactions
-- Filtrar transações concluídas no período, com categorias relevantes
-- e informações de cliente (via INNER JOIN)
WITH filtered_transactions AS (
    SELECT
        TO_CHAR(t.created_at, 'YYYY-MM') AS mes,             -- Mês/ano no formato ISO
        t.category                     AS categoria,          -- Categoria da transação
        t.amount_cents                                        -- Valor em centavos
    FROM
        transactions t
        INNER JOIN customers c ON t.customer_id = c.id
    WHERE
        t.status = 'completed'                                -- Apenas transações concluídas
        AND t.created_at >= '2025-10-24 00:00:00'::timestamp  -- Início do período (SARGável)
        AND t.created_at <  '2026-04-25 00:00:00'::timestamp  -- Fim do período (exclusivo) (SARGável)
        AND t.category IN ('subscription', 'one_time', 'refund', 'credit_adjustment')
    -- Índices utilizados pelo otimizador:
    --   idx_transactions_created_at  – busca rápida por data
    --   idx_transactions_status      – filtro eficiente do status
    --   idx_transactions_category    – filtro rápido da categoria
    -- A condição SARGável `t.created_at >= ... AND t.created_at < ...`
    -- permite scan via índice (index seek), evitando Full Table Scan.
)

-- Consulta principal: agregação por mês e categoria
SELECT
    mes,
    categoria,
    COUNT(*)                     AS quantidade_transacoes,   -- Número de transações
    ROUND(SUM(amount_cents) / 100.00, 2) AS volume_reais     -- Valor total em reais (2 casas decimais)
FROM
    filtered_transactions
GROUP BY
    mes, categoria
ORDER BY
    mes ASC,           -- Ordenação cronológica
    categoria ASC;     -- Ordenação alfabética por categoria