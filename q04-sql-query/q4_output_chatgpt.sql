-- 
-- Relatório Consolidado de Transações Mensais
-- Período: 6 meses corridos: 2025-10-24 a 2026-04-24
-- 

WITH transacoes_filtradas AS (
    -- 
    -- 1. Filtrar dados antes do JOIN para reduzir
    --    o volume processado e aproveitar índices
    -- 
    SELECT
        t.customer_id,
        t.category,
        t.amount_cents,
        t.created_at
    FROM
        transactions t
    WHERE
        t.status = 'completed'                                          -- Filtro por status (usa idx_transactions_status)
        AND t.category IN ('subscription', 'one_time', 'refund', 'credit_adjustment')  -- Categorias em produção (usa idx_transactions_category)
        AND t.created_at >=