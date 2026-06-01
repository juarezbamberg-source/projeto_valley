# Postmortem Técnico — Incidente de Degradação no chronos-api (v2.48.0)

## 1. Resumo Executivo

O deploy da v2.48.0 do chronos-api, realizado em 2026-04-23 18:42 UTC, provocou uma degradação progressiva de performance a partir de 2026-04-24 14:00 UTC, resultando em p99 de latência de 8100 ms, taxa de erro de 11,7%, exaustão do pool de conexões do Ledger, abertura do circuit breaker e acúmulo de ~50 mil mensagens no Reactor com consumer lag de 18 minutos. Recomenda-se rollback imediato da versão v2.48.0 para v2.47.0 como ação de contenção, por ser mais rápida e de menor risco do que scaling emergencial.

## 2. Causa Raiz

- O deploy v2.48.0 introduziu três mudanças que, combinadas, geraram o colapso:
  - Refatoração do pool de conexões do Ledger para uma nova biblioteca interna — possivelmente com configuração inadequada de max_connections (pool de 20 esgotado com 147 requisições em espera).
  - Redução do timeout do Ledger de 5s para 2s — agravou timeouts quando o pool já estava sob pressão.
  - Novo endpoint POST /v2/transactions/batch — aumentou a taxa de requisições ao Ledger por chamada de lote, amplificando o consumo de conexões.
  - Bump de psycopg 3.1.18 para 3.2.0 — pode ter alterado comportamento de pooling ou reconnect, embora não haja evidência direta nos logs.
- Métricas e logs mostram correlação direta: a latência p99 disparou de 780 ms (14:00) para 8100 ms (14:20), erro foi de 0,8% para 11,7%, e os logs registram "connection pool exhausted", timeouts de 2s e circuit breaker aberto com 87% de falhas.
- O limite de 250 conexões ativas ao RDS do Ledger (240 ativas no pico) confirma que o gargalo não é apenas de pool da aplicação, mas também de capacidade do banco.
- O erro "connection reset by peer" e o crescimento do backlog do Reactor (~800 msg/min) são consequências da incapacidade de processar requisições.

## 3. Timeline do Incidente

- **2026-04-23 18:42 UTC** — Deploy da v2.48.0 via Argo CD.
- **2026-04-24 13:30–13:45 UTC** — Métricas normais (p99 < 510 ms, erro < 0,3%). Sem sintomas.
- **2026-04-24 14:00 UTC** — Início da degradação: p99 780 ms, erro 0,8%, req/s 1780.
- **2026-04-24 14:10 UTC** — Piora: p99 2400 ms, erro 4,5%, req/s 2100.
- **2026-04-24 14:15 UTC** — Crise: p99 5200 ms, erro 8,2%, req/s 2400.
- **2026-04-24 14:19–14:20 UTC** — Ponto crítico:
  - Pool de conexões exausto (20 ativas, 147 waiting).
  - Timeouts de 2s no Ledger.
  - Circuit breaker abre (threshold 50%, atual 87%).
  - Reactor acumula 50.127 msgs, lag de 18 min.
  - Conexões ao RDS em 240/250.
  - p99 atinge 8100 ms, erro 11,7%.
- **2026-04-24 14:20 UTC + decisão** — Momento da análise; sem ação ainda.

## 4. Opção 1: Rollback

- **Prós**:
  - Reverte para versão estável (v2.47.0) que operava sem esses sintomas.
  - Não exige aprovisionamento adicional de infraestrutura.
  - Caminho conhecido e testado em rollbacks anteriores.
  - Tempo estimado: ~10 minutos (reverter sync do Argo CD + aguardar deploy dos pods).
- **Contras**:
  - Perde as funcionalidades do novo endpoint batch (impacto de negócio, não técnico imediato).
  - Consumo do pool de conexões pode voltar a níveis normais, mas o backlog do Reactor precisará ser drenado após rollback.
- **Risco**: Baixo. Rollback é operação padrão, sem dependência de aprovisionamento externo.

## 5. Opção 2: Scaling Emergencial

- **Prós**:
  - Mantém a nova versão e o endpoint batch operacionais.
  - Aumentar limite de conexões do RDS (ex: de 250 para 500) e pool da aplicação (ex: de 20 para 50) pode aliviar o gargalo imediato.
- **Contras**:
  - Tempo estimado ~30 minutos (alterar parâmetros do RDS, reiniciar pools, ajustar HPA se necessário).
  - Não resolve a causa raiz: a mudança de timeout de 5s para 2s e a possível regressão na biblioteca de pool continuam ativas.
  - Risk de sobrecarregar ainda mais o RDS se o pool for ampliado sem controle.
  - Pode mascarar problemas latentes no novo código.
- **Risco**: Médio. Depende de modificações em produção e não ataca a provável causa (refatoração do pool e timeout agressivo).

## 6. Recomendação Final

**Rollback imediato para v2.47.0**. Justificativa:
- O rollback é mais rápido (~10 min vs ~30 min) e de menor risco.
- A causa raiz está fortemente associada às mudanças na v2.48.0 (pool refatorado, timeout reduzido, novo endpoint). Mesmo com scaling, os timeouts de 2s continuariam gerando falhas sob pico.
- O backlog de 50k mensagens pode ser drenado após rollback com a versão estável, sem risco de nova degradação.
- Scaling emergencial seria uma aposta com risco de novas falhas (ex: RDS overload ou pool mal configurado).

## 7. Próximos Passos

- **Imediato (pós-rollback)**:
  - Verificar se métricas retornam aos níveis normais (p99 < 500 ms, erro < 0,5%) nos primeiros 15 minutos.
  - Reiniciar o consumer do Reactor para acelerar drenagem do backlog.
- **Curto prazo (até 48h)**:
  - Analisar em staging a nova biblioteca de pool de conexões: confirmar max_connections e comportamento de timeout.
  - Revisar o timeout de 2s — voltar a 5s ou implementar retry com backoff.
  - Testar o endpoint batch com carga equivalente à produção para validar.
  - Avaliar se o bump do psycopg introduziu mudanças de compatibilidade.
- **Médio prazo**:
  - Implementar monitoring granular de pool de conexões por serviço.
  - Ajustar HPA para escalar baseado em conexões ativas e não só CPU/memória.