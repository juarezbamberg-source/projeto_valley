# Q04 - Relatório Mensal de Transações do Ledger | Prompt B-A-B

## Framework Utilizado
**B-A-B (Before, After, Bridge)**

## Prompt Estruturado

### Before
Atualmente, o banco ledger_prod tem dados brutos de transações espalhados em múltiplas tabelas (transactions, accounts, users) sem agregação ou análise consolidada. Jennifer precisa manualmente compilar relatórios mensais, o que é demorado e propenso a erros.

### After
Um relatório SQL estruturado que:
1. Agregue transações por tipo (débito, crédito, transferência, etc.)
2. Calcule totais, médias, contagens e desvios padrão por categoria
3. Identifique anomalias (transações > 2 desvios padrão, taxa de falha > 5%, etc.)
4. Mostre top 10 usuários por volume de transações
5. Exiba tendências diárias/semanais do mês
6. Retorne resultados em formato estruturado (JSON ou tabelas SQL)

### Bridge
Escreva uma query SQL (ou conjunto de queries) que:
- Conecte transactions, accounts e users
- Filtre pelo último mês completo (use CURRENT_DATE para calcular dinamicamente)# Q04 - Relatório Mensal de Transações do Ledger | Validação Técnica

## Validação de Sintaxe SQL

### ChatGPT
- **Status**: ❌ Não é SQL executável
- **Verificações**:
  - Não contém código SQL ❌
  - Não usa CTEs ❌
  - Não usa window functions ❌
  - Não usa GROUP BY ❌
  - Não usa CASE WHEN ❌
  - É um relatório estruturado, não código ❌

### Claude
- **Status**: ❌ Não é SQL executável
- **Verificações**:
  - Não contém código SQL ❌
  - Mistura análise comparativa com prompt ❌
  - Fora do escopo de validação de queries ❌
  - Não é executável em PostgreSQL ❌

### Gemini
- **Status**: ❌ Não é SQL executável
- **Verificações**:
  - Não contém código SQL ❌
  - Não usa CTEs ❌
  - Não usa window functions ❌
  - É um plano FinOps, não código ❌

## Checklist de Requisitos

| Requisito | ChatGPT | Claude | Gemini |
|-----------|---------|--------|--------|
| Código SQL executável | ❌ | ❌ | ❌ |
| CTEs (Common Table Expressions) | ❌ | ❌ | ❌ |
| Window functions | ❌ | ❌ | ❌ |
| GROUP BY para agregação | ❌ | ❌ | ❌ |
| CASE WHEN para outliers | ❌ | ❌ | ❌ |
| Comentários explicativos | ❌ | ❌ | ❌ |
| Otimização para performance | ❌ | ❌ | ❌ |
| Pronto para executar | ❌ | ❌ | ❌ |

## Problema Identificado

**Os 3 provedores não interpretaram corretamente o prompt B-A-B.** O prompt solicitava explicitamente:
- Query SQL com estrutura específica
- CTEs, window functions, GROUP BY, CASE WHEN
- Comentários explicando cada seção

**Todos entregaram relatórios de análise/planejamento ao invés de código SQL executável.**

## Recomendações para Próximas Execuções

1. **Ser mais explícito**: "Retorne APENAS código SQL, não relatório"
2. **Incluir exemplo**: Mostrar estrutura esperada das CTEs
3. **Especificar banco**: "PostgreSQL 12+ com sintaxe padrão"
4. **Validar saída**: Pedir para incluir `EXPLAIN ANALYZE` no final
5. **Testar localmente**: Executar a query em um banco de teste antes de usar em produção

## Conclusão

Nenhum dos 3 outputs atende aos requisitos técnicos. Recomenda-se refinar o prompt B-A-B para ser mais específico sobre a necessidade de SQL executável.
- Agregue dados com GROUP BY por tipo de transação, categoria, usuário
- Use window functions para calcular percentis e desvios padrão
- Identifique outliers com CASE WHEN e cálculos estatísticos
- Retorne múltiplas CTEs (Common Table Expressions) para cada seção do relatório
- Inclua comentários explicando cada seção
- Seja otimizado para performance (índices, EXPLAIN ANALYZE)

## Componentes do Framework

| Componente | Descrição | Aplicação |
|-----------|-----------|-----------|
| **Before** | Estado atual problemático | Dados brutos sem agregação, compilação manual |
| **After** | Estado desejado | Relatório SQL estruturado com agregações e anomalias |
| **Bridge** | Caminho de transformação | Query SQL com CTEs, window functions, GROUP BY, CASE WHEN |