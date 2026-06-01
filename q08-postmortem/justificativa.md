# Q08 - Postmortem Técnico de Incidente em Produção | Justificativa Comparativa

## Framework Escolhido: T-A-G (Task, Action, Goal)

### Por que T-A-G foi a melhor escolha?

**T-A-G é goal-oriented e orientado a SLA**, perfeito para incidentes em produção onde:
- **Task** define claramente o que fazer (analisar e recomendar ação)
- **Action** estrutura os passos de análise (correlacionar deploy, métricas, logs)
- **Goal** estabelece o objetivo mensurável (decisão em 20 min, 80%+ confiança, minimizar risco)

Isso permite que o modelo produza um postmortem **focado em resultado**, não apenas em descrição.

---

## Comparação com Frameworks Alternativos

### Alternativa 1: C-A-R-E (Context, Action, Result, Example)

**O que se ganharia:**
- Mais contexto técnico detalhado (C = Context)
- Exemplo de postmortem bem estruturado (E = Example)
- Potencial para output mais rico e padronizado

**O que se perderia:**
- Foco em SLA e deadline (20 minutos)
- Objetivo mensurável explícito (Goal)
- Estrutura orientada a decisão rápida
- C-A-R-E é melhor para **padronização de formato**, não para **análise de incidente com urgência**

**Conclusão:** C-A-R-E seria mais verboso e menos urgente. T-A-G é mais direto.

---

### Alternativa 2: R-I-S-E (Role, Input, Steps, Expectation)

**O que se ganharia:**
- Estrutura procedural clara (Steps)
- Definição de papel (Role = SRE sênior)
- Expectativas explícitas (Expectation)

**O que se perderia:**
- Foco em objetivo mensurável (Goal)
- Estrutura orientada a ação/decisão (Action)
- Urgência e SLA (20 minutos)
- R-I-S-E é melhor para **runbooks procedurais**, não para **análise de incidente com decisão crítica**

**Conclusão:** R-I-S-E seria mais procedural e menos decisório. T-A-G é mais orientado a resultado.

---

## Análise dos Outputs

### Claude
- **Status**: ✅ Melhor output
- **Pontos fortes**: 
  - Postmortem mais completo e estruturado
  - Tabela de timeline formatada (4 linhas com horário, evento, métricas)
  - Checklist executável de rollback (passos diretos)
  - Gráfico ASCII da degradação (visualização clara)
  - Campo de revisão/assinatura (profissionalismo)
  - Próximos passos mais detalhados (imediato + investigação em sprint + prevenção + checklist)
  - Confiança na causa raiz explícita (85%)
  - Análise profunda do pool psycopg 3.2.0 e herança de config
- **Pontos fracos**: 
  - Nenhum identificado

### ChatGPT
- **Status**: ⚠️ Segundo lugar - Bom, mas menos estruturado
- **Pontos fortes**: 
  - Postmortem completo e bem escrito
  - Narrativa clara com timestamps
  - Tempo de rollback especificado (~10 min)
  - Análise das 3 mudanças (pool library, timeout, batch endpoint, psycopg)
  - Próximos passos bem definidos (imediato, curto prazo, médio prazo)
- **Pontos fracos**: 
  - Sem tabelas ou visualizações
  - Sem checklist executável
  - Sem gráfico ASCII
  - Sem campo de revisão
  - Confiança na causa raiz não explícita
  - Próximos passos menos detalhados que Claude

### Gemini
- **Status**: ⚠️ Terceiro lugar - Enxuto, mas menos profundo
- **Pontos fortes**: 
  - Metadados completos no cabeçalho (SEV-0, SRE, Doc Brown)
  - Tempo de rollback mais rápido (~3 min via Argo CD)
  - Estrutura enxuta e direta
  - Risco do Scaling bem avaliado (Altíssimo)
- **Pontos fracos**: 
  - Menos profundidade na causa raiz
  - Sem tabelas ou visualizações
  - Sem checklist executável
  - Sem gráfico ASCII
  - Sem campo de revisão
  - Próximos passos menos detalhados

## Comparação Estrutural

| Aspecto | Claude | ChatGPT | Gemini |
|---------|--------|---------|--------|
| **Completude** | ✅ Muito completo | ✅ Completo | ⚠️ Enxuto |
| **Tabelas/Visualizações** | ✅ Sim (timeline + ASCII) | ❌ Não | ❌ Não |
| **Checklist executável** | ✅ Sim | ❌ Não | ❌ Não |
| **Confiança explícita** | ✅ 85% | ❌ Não | ❌ Não |
| **Próximos passos** | ✅ Muito detalhado | ✅ Detalhado | ⚠️ Básico |
| **Profissionalismo** | ✅ Campo de revisão | ❌ Não | ⚠️ Metadados |
| **Tempo rollback** | ⚠️ Não especifica | ✅ ~10 min | ✅ ~3 min |
| **Pronto para produção** | ✅ Sim | ✅ Sim | ✅ Sim |

## Checklist de Requisitos

| Requisito | Claude | ChatGPT | Gemini |
|-----------|--------|---------|--------|
| Resumo Executivo claro | ✅ | ✅ | ✅ |
| Causa Raiz com confiança | ✅ 85% | ✅ Sim | ✅ Sim |
| Timeline do incidente | ✅ Tabela | ✅ Narrativa | ✅ Bullets |
| Análise deploy + métricas | ✅ | ✅ | ✅ |
| Análise logs (pool, timeout, circuit breaker) | ✅ | ✅ | ✅ |
| Verificação dependências | ✅ | ✅ | ✅ |
| Avaliação cluster | ✅ | ✅ | ✅ |
| Opção 1: Rollback (prós, contras, tempo, risco) | ✅ | ✅ | ✅ |
| Opção 2: Scaling (prós, contras, tempo, risco) | ✅ | ✅ | ✅ |
| Recomendação Final | ✅ | ✅ | ✅ |
| Próximos Passos | ✅ Muito detalhado | ✅ Detalhado | ✅ Básico |
| Executável em <20 min | ✅ | ✅ | ✅ |

## Recomendações de Todos os Provedores

**Todos os 3 recomendaram: ROLLBACK para v2.47.0**

| Provedor | Justificativa | Tempo | Risco do Scaling |
|----------|---------------|-------|-----------------|
| **Claude** | Remove causa raiz, risco baixo, recuperação previsível | Não especifica | Alto |
| **ChatGPT** | Mais rápido, risco baixo, remove causa raiz | ~10 min | Médio |
| **Gemini** | Mitigação mais segura via Argo CD | ~3 min | Altíssimo |

## Conclusão Crítica

**Claude foi o melhor output** por oferecer:
- ✅ Postmortem mais completo e estruturado
- ✅ Tabelas e visualizações (timeline + ASCII)
- ✅ Checklist executável de rollback
- ✅ Confiança explícita (85%)
- ✅ Próximos passos mais detalhados (imediato + sprint + prevenção + checklist)
- ✅ Campo de revisão/assinatura (profissionalismo)
- ✅ Pronto para usar imediatamente em produção

**ChatGPT vem em segundo** — postmortem bem escrito, mas menos estruturado (sem tabelas, sem checklist, sem visualizações).

**Gemini fica em terceiro** — enxuto e direto, mas menos profundo e menos estruturado.

## Por que T-A-G foi a melhor escolha de framework?

1. **Task** define claramente o que fazer (analisar e recomendar)
2. **Action** estrutura os passos de análise (7 passos específicos)
3. **Goal** estabelece o objetivo mensurável (20 min, 80%+ confiança, minimizar risco)

Isso permitiu que todos os 3 provedores produzissem postmortems **focados em resultado e decisão**, não apenas em descrição. T-A-G foi superior a C-A-R-E (mais verboso) e R-I-S-E (mais procedural).

## Recomendações para Próximas Execuções

1. **Usar Claude como padrão** para postmortems de incidente
2. **Publicar o postmortem do Claude** como template para o time
3. **Executar o checklist de rollback** do Claude imediatamente
4. **Investigar em sprint** as mudanças do v2.48.0 (pool library, timeout, psycopg)
5. **Implementar prevenção** (testes de carga, validação de config, alertas)