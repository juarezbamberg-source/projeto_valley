# Q04 - Relatório Mensal de Transações do Ledger | Justificativa Comparativa

## Framework Utilizado
**B-A-B (Before, After, Bridge)**

## Análise dos Outputs

### ChatGPT
- **Status**: ⚠️ Relatório estruturado, mas não é SQL puro
- **Pontos fortes**: 
  - Conteúdo completo e bem estruturado
  - Tabela comparativa clara
  - Roadmap detalhado
  - Análise de riscos incluída
  - Boa organização visual
- **Pontos fracos**: 
  - Não é uma query SQL executável
  - Foco em planejamento ao invés de validação de dados
  - Inconsistências em alguns trechos
  - Não inclui CTEs ou window functions

### Claude
- **Status**: ⚠️ Relatório híbrido, fora do escopo
- **Pontos fortes**: 
  - Análise comparativa bem organizada
  - Identificação clara de pontos fortes e fracos
  - Estrutura lógica
- **Pontos fracos**: 
  - Mistura comparação anterior com novo prompt R-T-F
  - Não é uma query SQL executável
  - Fora do escopo de validação de queries SQL
  - Menos alinhado ao pedido atual

### Gemini
- **Status**: ⚠️ Relatório FinOps, não é SQL puro
- **Pontos fortes**: 
  - Plano FinOps bem estruturado
  - Foco em custos e ROI
  - Projeções financeiras
- **Pontos fracos**: 
  - Não é uma query SQL executável
  - Mais resumido e menos completo
  - Sem tabela comparativa
  - Fora do escopo de validação de queries SQL

## Comparação Estrutural

| Aspecto | ChatGPT | Claude | Gemini |
|---------|---------|--------|--------|
| **Tipo de conteúdo** | Relatório estruturado | Análise híbrida | Plano FinOps |
| **É SQL executável?** | ❌ | ❌ | ❌ |
| **Estrutura** | Seções + tabela + bullets | Análise + prompt | Seções + bullets |
| **Completude** | Alta | Média | Média |
| **Alinhamento ao escopo** | Parcial | Baixo | Baixo |
| **Clareza** | Boa | Boa | Boa |
| **Pronto para produção** | ❌ | ❌ | ❌ |

## Problema Identificado

**Os 3 outputs não são queries SQL executáveis.** O prompt B-A-B solicitava:
- Query SQL com CTEs (Common Table Expressions)
- Window functions para cálculos estatísticos
- Agregações com GROUP BY
- Identificação de outliers com CASE WHEN
- Comentários explicando cada seção
- Otimização para performance

**Nenhum dos 3 provedores entregou isso.** Todos entregaram relatórios de análise/planejamento ao invés de código SQL.

## Decisão Final

**Nenhum dos 3 outputs está 100% correto.** Porém:
- **ChatGPT** é o melhor relatório estruturado (mais completo e organizado)
- **Claude** oferece a melhor análise comparativa (mas fora do escopo)
- **Gemini** é o mais resumido (menos útil para este contexto)

## Conclusão

O prompt B-A-B não foi interpretado corretamente pelos 3 provedores. Recomenda-se:
1. Refinar o prompt para ser mais explícito sobre a necessidade de SQL executável
2. Adicionar exemplo de query esperada no prompt
3. Especificar claramente: "Retorne APENAS código SQL, não relatório"
4. Incluir estrutura esperada das CTEs no exemplo