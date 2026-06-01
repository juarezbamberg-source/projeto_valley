TASK:
Escreva uma query SQL PostgreSQL que gere um relatório consolidado 
de transações mensais do banco ledger_prod para os últimos 6 meses 
corridos (período: 2025-10-24 até 2026-04-24).

ACTION:
A query deve executar as seguintes ações:
1. Conectar as tabelas transactions e customers
2. Filtrar apenas transações com status = 'completed'
3. Filtrar apenas as categorias em produção: subscription, one_time, refund, credit_adjustment
4. Filtrar apenas o período dos últimos 6 meses corridos (2025-10-24 até 2026-04-24)
5. Agrupar os dados por mês (formato YYYY-MM) e por categoria
6. Calcular duas métricas por linha:
   - Quantidade de transações (COUNT(*))
   - Volume total em reais (SUM(amount_cents) / 100.00, com 2 casas decimais)
7. Ordenar o resultado por mês crescente (ASC), depois por categoria crescente (ASC)
8. Retornar as colunas: mes (YYYY-MM), categoria, quantidade_transacoes, volume_reais

GOAL:
Produzir uma query SQL que:
- Seja válida e executável no PostgreSQL sem erros
- Use os índices existentes (idx_transactions_created_at, idx_transactions_status, idx_transactions_category)
- Retorne resultados em formato estruturado e fácil de interpretar
- Inclua comentários explicando cada seção da query
- Seja otimizada para performance (use CTEs se necessário para clareza)
- Valide que amount_cents está convertido corretamente para reais (dividir por 100)
- Seja pronta para produção e segura