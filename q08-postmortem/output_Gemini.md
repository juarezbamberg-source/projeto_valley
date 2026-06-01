# ## POSTMORTEM TÉCNICO: Instabilidade Crítica na Chronos API

* **Data do Incidente**: 2026-04-24
* **Severidade**: SEV-0 (Crítico)
* **Autor**: SRE On-Call
* **Destinatário**: Doc Brown / Engenharia Core

---

### ### 1. Resumo Executivo
Durante o pico de tráfego do dia 2026-04-24, a **Chronos API** sofreu uma degradação severa de performance a partir das 14:00 UTC, com a latência p99 saltando de `420ms` para `8100ms` e a taxa de erro atingindo `11,7%` às 14:20 UTC. O incidente foi desencadeado pelo deploy da versão `v2.48.0` (ocorrido em 2026-04-23 18:42:11 UTC), que introduziu uma nova biblioteca interna de gerenciamento de conexões e reduziu o timeout do banco de dados Ledger de `5s` para `2s`. Sob carga de pico (2.650 req/s), o pool de conexões de banco de dados esgotou-se nos pods da API, gerando um efeito cascata que quase saturou o RDS PostgreSQL (240/250 conexões ativas) e represou o processamento de filas no Reactor SQS (mais de 50 mil mensagens acumuladas). **Recomendamos o Rollback imediato para a versão v2.47.0**, estimado em 3 minutos via Argo CD, como a única ação segura para mitigar o incidente sem risco de indisponibilidade do banco de dados.

---

### ### 2. Causa Raiz
A análise técnica aponta para uma falha de dimensionamento e comportamento da nova biblioteca de conexões introduzida na versão `v2.48.0`, agravada pelo novo endpoint de lote (`POST /v2/transactions/batch`). 

1. **Esgotamento de Pool Local**: Os logs do pod revelam que o pool de conexões de cada instância da API (limitado a 20) foi completamente exaurido: `connection pool exhausted (max=20, active=20, waiting=147)`. Com 12 pods ativos rodando no limite do HPA, a API tentava manter até 240 conexões simultâneas com o banco Ledger.
2. **Saturação do RDS**: O limite físico de conexões do RDS PostgreSQL (`ledger_prod`) é de 250. No pico do incidente, o banco atingiu `240/250` conexões ativas. O banco começou a derrubar conexões ativas por sobrecarga (`connection reset by peer`).
3. **Estouro de Timeout e Circuit Breaker**: A redução do timeout de `5s` para `2s` fez com que queries legítimas de lote do novo endpoint `/v2/transactions/batch` falhassem prematuramente por timeout (`query timeout after 2000ms`). Isso ativou o Circuit Breaker da API (`ledger-client OPEN`), que passou a rejeitar requisições imediatamente para proteger o sistema, interrompendo também o despacho de mensagens para o Reactor SQS.

---

### ### 3. Timeline do Incidente
* **2026-04-23 18:42:11 UTC**: Sincronização bem-sucedida da versão `v2.48.0` via Argo CD. Tráfego de baixa intensidade mascara o problema de concorrência do pool.
* **2026-04-24 13:30 UTC**: Início do pico de tráfego diário. Sistema estável com 1.200 req/s, latência p99 em `420ms` e taxa de erro residual (`0,2%`).
* **2026-04-24 14:00 UTC**: Tráfego sobe para 1.780 req/s. Latência p99 sobe para `780ms`. Primeiros alertas internos de contenção de pool começam a registrar nos logs.
* **2026-04-24 14:10 UTC**: HPA atinge o limite máximo de 12 pods. Latência p99 dispara para `2400ms` e taxa de erro sobe para `4,5%`.
* **2026-04-24 14:15 UTC**: Conexões no RDS PostgreSQL atingem 240/250. O endpoint `/v2/transactions/batch` falha massivamente por timeout. Taxa de erro geral chega a `8,2%`.
* **2026-04-24 14:19:48 UTC**: Logs registram exaustão completa do pool e abertura do Circuit Breaker (`ledger-client OPEN`).
* **2026-04-24 14:20 UTC**: Latência p99 atinge o pico crítico de `8100ms` com `11,7%` de erro. Fila do Reactor SQS acumula 50.127 mensagens com lag de 18 minutos.

---

### ### 4. Opção 1: Rollback para v2.47.0
Consiste em reverter a imagem da aplicação para a versão anterior estável através do Argo CD.

* **Prós**:
  * Desfaz a refatoração do cliente do Ledger, retornando para a biblioteca de pool estável e testada sob carga.
  * Restaura o timeout de conexão seguro de `5s`, eliminando os falsos-positivos de timeout de 2s.
  * Desativa temporariamente o endpoint `/v2/transactions/batch` que está gerando as queries pesadas.
  * Processo automatizado e extremamente rápido via GitOps/Argo CD.
* **Contras**:
  * Clientes que já integraram com o novo endpoint `/v2/transactions/batch` receberão erro `404` (porém, o endpoint já está com taxa de falha de 100% no momento).
* **Tempo Estimado**: ~3 minutos (tempo de deploy e inicialização dos pods estáveis).
* **Risco**: **Muito Baixo**. A versão `v2.47.0` operou por semanas sem qualquer vazamento ou contenção de conexões.

---

### ### 5. Opção 2: Scaling Emergencial
Consiste em aumentar o limite de conexões do RDS PostgreSQL (`max_connections`) e expandir o tamanho do pool nos pods da API (ex: de 20 para 40).

* **Prós**:
  * Mantém a versão `v2.48.0` ativa com as novas funcionalidades e o endpoint batch em produção.
* **Contras**:
  * Aumentar o pool dos pods para 40 exigiria uma capacidade de até 480 conexões concorrentes no RDS (`12 pods * 40`).
  * O aumento de `max_connections` no RDS PostgreSQL exige a modificação de um Parameter Group e, frequentemente, um **reboot da instância de banco de dados**, gerando indisponibilidade total de 2 a 5 minutos.
  * Não resolve um eventual vazamento de conexões (*connection leak*) na nova biblioteca, apenas adia o estouro do limite.
* **Tempo Estimado**: ~15 a 20 minutos (alteração de infraestrutura de banco e redeploy de variáveis de ambiente da API).
* **Risco**: **Altíssimo**. Risco de travar o banco de dados por exaustão de memória RAM (cada conexão ativa no PostgreSQL consome memória dedicada no SO do RDS).

---

### ### 6. Recomendação Final
**Recomendamos a execução imediata do Rollback para a versão v2.47.0.**

**Justificativa**: O scaling emergencial do banco de dados em meio a um incidente de pico de tráfego apresenta riscos inaceitáveis de indisponibilidade total do Ledger PostgreSQL devido à necessidade de reboot e potencial exaustão de memória. O rollback ataca diretamente a causa raiz (a nova biblioteca de pool de conexões não testada sob estresse e o timeout agressivo de 2s), retornando o sistema para um estado conhecido e estável em menos de 3 minutos, com risco zero para a integridade dos dados.

---

### ### 7. Próximos Passos (Ações Imediatas Pós-Mitigação)
1. **Executar o Rollback**: Acionar o botão "Rollback" no Argo CD para a tag `v2.47.0` ou reverter o commit no repositório de infraestrutura.
2. **Monitorar Recuperação**: Acompanhar a drenagem de conexões no RDS (deve cair de 240 para <150) e a redução da latência p99 para níveis normais (<500ms).
3. **Drenar Fila do Reactor**: Monitorar o consumo das 50 mil mensagens acumuladas no SQS. Se necessário, escalar temporariamente os workers do Reactor para acelerar a vazão.
4. **Análise em Ambiente Isolado**: Isolar a versão `v2.48.0` em ambiente de staging para realizar testes de carga (*load testing*) focados no comportamento do pool de conexões sob estresse.
5. **Ajuste de Instrumentação**: Adicionar métricas específicas de conexões ativas/esperando do pool da API no dashboard do Grafana para alertas preventivos de exaustão de recursos.