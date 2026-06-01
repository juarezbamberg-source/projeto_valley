Before: Atualmente, o banco ledger_prod tem dados brutos de transações espalhados em múltiplas tabelas (transactions, accounts, users) sem agregação ou análise consolidada. Jennifer precisa manualmente compilar relatórios mensais, o que é demorado e propenso a erros.

After: Um relatório SQL estruturado que:
1. Agregue transações por tipo (débito, crédito, transferência, etc.)
2. Calcule totais, médias, contagens e desvios padrão por categoria
3. Identifique anomalias (transações > 2 desvios padrão, taxa de falha > 5%, etc.)
4. Mostre top 10 usuários por volume de transações
5. Exiba tendências diárias/semanais do mês
6. Retorne resultados em formato estruturado (JSON ou tabelas SQL)

Bridge: Escreva uma query SQL (ou conjunto de queries) que:
- Conecte transactions, accounts e users
- Filtre pelo último mês completo (use CURRENT_DATE para calcular dinamicamente)
- Agregue dados com GROUP BY por tipo de transação, categoria, usuário
- Use window functions para calcular percentis e desvios padrão
- Identifique outliers com CASE WHEN e cálculos estatísticos
- Retorne múltiplas CTEs (Common Table Expressions) para cada seção do relatório
- Inclua comentários explicando cada seção
- Seja otimizado para performance (índices, EXPLAIN ANALYZE)