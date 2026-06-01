Postmortem Técnico: Incidente Crítico – Chronos API
Data do incidente: 24 de abril de 2026 Responsável pela análise: Plantonista SRE (Time de Plataforma)
1. Resumo Executivo
Em 24 de abril de 2026, durante pico de tráfego (14:00 UTC), o deploy v2.48.0 causou degradação catastrófica na Chronos API: P99 latency saltou de 420ms para 8.1s e erro rate subiu de 0,2% para 11,7%. A causa raiz foi a redução do timeout do cliente Ledger de 5s para 2s, combinada com a refatoração do pool de conexões, que exauriu rapidamente as conexões disponíveis no RDS (240/250 ativas). A recomendação imediata é Rollback para v2.47.0, interrompendo o fluxo de novas requisições com falha e permitindo recuperação do sistema em <10 minutos.

2. Causa Raiz (Confiança: 85%)
A análise correlacionada dos dados de deploy, logs e métricas aponta para três fatores combinados:
1.	Redução do timeout Ledger (5s → 2s): No pico de tráfego, consultas ao Ledger que antes completavam em 3-4s passaram a exceder o novo timeout de 2s. Isso gerou explosão de timeouts e retentativas.
2.	Refatoração do pool de conexões: A nova biblioteca (psycopg 3.2.0) não herdou corretamente as configurações de pool do cliente anterior. O número máximo de conexões simultâneas no lado da aplicação não foi limitado adequadamente, sobrecarregando o RDS (240/250 conexões).
3.	Efeito dominó: Conexões exauridas → timeouts → retentativas → circuit-breaker aberto → requisições falhadas → fila SQS cresce (Reactor com 50.127 mensagens e lag de 18min) → degradação generalizada.
Evidência direta dos logs:
14:19:48 connection pool exhausted (max=20, active=20, waiting=147)<br/> 14:19:49 query timeout after 2000ms<br/> 14:19:51 circuit-breaker OPEN (87% erro)

3. Timeline do Incidente
| 2026-04-24 13:30 | Sistema estável (pré-pico) | P99=420ms, err=0,2% |
| 14:10 | Degradação acelerada | P99=2,4s, err=4,5% |
| 14:19 | Exaustão do pool, circuit-breaker abre | P99=8,1s, err=11,7% |
| 14:22 | Decisão de rollback tomada | – |

4. Opção 1: Rollback para v2.47.0
Prós
●	Restaura comportamento estável testado por semanas
●	Elimina imediatamente a causa raiz (timeout reduzido + pool refatorado)
●	Recupera latência esperada (P99 ~400ms)
●	Não aumenta custo de infraestrutura
Contras
●	Desfaz novas funcionalidades (POST /batch)
●	Necessita novo deploy para reintroduzir mudanças corrigidas
●	Perde momento de lançamento (se houver pressão comercial)
Tempo estimado
●	Execução: 3–5 minutos (Argo CD sync)
●	Estabilização: +5 minutos (dreno de requisições pendentes)
Risco residual
●	Baixo: v2.47.0 já rodou por dias sem incidentes.

5. Opção 2: Scaling Emergencial
Prós
●	Mantém novas funcionalidades ativas
●	Pode aliviar pressão temporariamente
Contras
●	Não resolve causa raiz (timeout vs. capacidade de resposta)
●	RDS já está no limite (240/250 conexões) – escalar pods só piora
●	Aumenta custo de infraestrutura desnecessariamente
●	HPA já no máximo (12/12 pods) sem melhora
●	Risco de crash no RDS (atingir limite de conexões)
Tempo estimado
●	Aumentar pods manualmente: 2 minutos
●	Aumentar RDS connections: 10 minutos + reboot
●	Resultado: provável falha contínua
Risco residual
●	Alto: pode causar queda total do RDS e perda de dados.

6. Recomendação Final
Escolha: Rollback para v2.47.0Justificativa técnica:
A degradação não é causada por falta de capacidade (CPU/memória dentro dos limites, HPA já no máximo), mas sim por uma mudança comportamental no cliente Ledger. Reduzir timeout sem aumentar pool ou sem testar em pico quebra a resiliência do sistema. Escalar pods não resolve o gargalo (exaustão de conexões no RDS) e pode agravar ao tentar abrir mais conexões. Rollback é a única ação que elimina a causa raiz com risco mínimo e tempo de recuperação previsível.
Impacto esperado:
●	Latência retorna a ~400ms em até 5 minutos
●	Erro rate cai para <1%
●	A fila SQS será drenada naturalmente em ~20 minutos

7. Próximos Passos
Ações Imediatas (pós-incidente)
●	Executar rollback no Argo CD: argocd app sync chronos-api --revision v2.47.0
●	Monitorar métricas por 10 minutos (P99, erro rate, pool de conexões)
●	Limpar fila SQS se lag persistir (forçar reprocessamento)
●	Comunicar resolução no canal #oncall-chronos
Investigação Profunda (Sprint seguinte)
●	Revisar a biblioteca psycopg 3.2.0 e as configurações de pool herdadas
●	Aumentar timeout padrão do Ledger para 4s (balanço entre segurança e pico)
●	Adicionar métrica de waiting connections no dashboard do Grafana
●	Implementar testes de carga com cenário de pico (>2.000 req/s) antes de novo deploy do /batch
Prevenção Futura
●	Incluir no pipeline de CI um teste de estresse com tráfego equivalente ao pico histórico
●	Adicionar alerta para exaustão de pool de conexões (ativo=20 por >30s)
●	Revisar política de timeouts em serviços upstream: timeout deve ser >= P99 do serviço downstream + margem

Checklist de Execução (Rollback)
| 2 | kubectl rollout status deployment/chronos-api -n production | deployment "chronos-api" successfully rolled out | | 4 | Verificar P99 e erro rate no Grafana | P99 < 500ms, err < 1% por 5 minutos |

Descrição Gráfica da Degradação
P99 (ms)  |                    * 8.000     |
6.000     |
4.000     |
2.000     |
*    420    |
(13:30)           +----------------------------------           13:30  14:00  14:10  14:15  14:20
O gráfico mostra degradação exponencial a partir das 14:00 UTC, com crescimento acelerado após 14:10, quando o pool de conexões começou a ser exaurido. O patamar de 8.100ms coincide com a abertura do circuit-breaker (87% de erro).

Local e data: São Paulo, 01 de junho de 2026
Assinatura: Plantonista SRE (Time de Plataforma)
Revisado por: [nome do time sênior]
