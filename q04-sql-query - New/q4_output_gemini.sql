-- ============================================================================
-- Relatório Mensal Consolidado de Transações (Últimos 6 Meses)
-- Banco: ledger_prod | Período: 2025-10-24 a 2026-04-24
-- Índices utilizados: idx_transactions_created_at, idx_transactions_status,
--                     idx_transactions_category
-- ============================================================================

SELECT
    TO_CHAR(t.created_at, 'YYYY-MM')      AS mes,            -- Mês no formato YYYY-MM
    t.category                            AS categoria,      -- Categoria da transação
    COUNT(*)                              AS qtd_transacoes, -- Quantidade de transações no grupo
    ROUND(SUM(t.amount_cents) / 100.00, 2) AS volume_reais   -- Volume total convertido para reais

-- Tabela principal com JOIN otimizado pela chave estrangeira
FROM transactions t
INNER JOIN customers c ON t.customer_id = c.id

-- Filtros SARGable que aproveitam os índices existentes
WHERE
    t.status = 'completed'                                      -- idx_transactions_status
    AND t.category IN ('subscription', 'one_time', 'refund', 'credit_adjustment')  -- idx_transactions_category
    AND t.created_at >= '2025-10-24 00:00:00'::timestamp        -- idx_transactions_created_at
    AND t.created_at <  '2026-04-25 00:00:00'::timestamp        -- idx_transactions_created_at (limite exclusivo)
-- Nota: O intervalo semiaberto [2025-10-24, 2026-04-25) garante que todas as
-- transações do dia 2026-04-24 sejam incluídas sem depender de funções na coluna.

-- Agregação mensal por categoria
GROUP BY
    TO_CHAR(t.created_at, 'YYYY-MM'),
    t.category

-- Ordenação cronológica e alfabética
ORDER BY
    mes ASC,
    categoria ASC;