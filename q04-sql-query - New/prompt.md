Você é um analista de dados sênior especializado em PostgreSQL.

Sua tarefa é escrever uma única query SQL para o banco ledger_prod que gere um relatório consolidado de transações mensais para os últimos 6 meses corridos, considerando o período de 2025-10-24 até 2026-04-24, com foco na apresentação executiva de Jennifer.

Requisitos da query:
1. Fazer JOIN entre as tabelas transactions e customers usando:
   transactions.customer_id = customers.id
2. Filtrar apenas transações com:
   status = 'completed'
3. Filtrar apenas as categorias em produção:
   subscription, one_time, refund, credit_adjustment
4. Considerar apenas o período de 6 meses corridos:
   de 2025-10-24 até 2026-04-24
5. Agrupar os dados por:
   - mês no formato YYYY-MM
   - categoria
6. Calcular, por grupo, as seguintes métricas:
   - quantidade de transações: COUNT(*)
   - volume total em reais: SUM(amount_cents) / 100.00
   - garantir 2 casas decimais no resultado
7. Ordenar o resultado final por:
   - mês crescente (ASC)
   - categoria crescente (ASC)

Requisitos de saída:
- A query deve ser válida e executável no PostgreSQL sem erros
- Retornar as colunas exatamente nesta ordem e com estes nomes:
  mes, categoria, qtd_transacoes, volume_reais
- Apresentar volume_reais em formato numérico com duas casas decimais, por exemplo: 15234.90
- Ser otimizada para performance, aproveitando os índices existentes:
  idx_transactions_created_at, idx_transactions_status, idx_transactions_category
- Conter comentários explicativos em português em cada seção da query
- Ser pronta para produção, segura e fácil de interpretar
- Usar CTEs somente se isso melhorar a clareza
- Entregar a resposta final em um único bloco de código SQL, pronto para copiar e executar

Estrutura esperada da query:
- Comentário de abertura explicando o objetivo
- Seção de filtragem das transações
- Seção de JOIN com customers
- Seção de agregação mensal por categoria
- Seção final de ordenação e seleção das colunas

Considere que a query deve ser clara, legível e sem ambiguidade, preservando precisão nos cálculos e no filtro temporal.