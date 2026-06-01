xEste runbook foi estruturado para guiar qualquer engenheiro de plantão (on-call) no diagnóstico e na mitigação rápida do alerta de memória alta na **Chronos API**. O objetivo é restabelecer a estabilidade do sistema em menos de 15 minutos (SLA comercial), garantindo a segurança operacional.

O mapa mental interativo acima ilustra o fluxo lógico de tomada de decisão que seguiremos a seguir.

---

# ## RUNBOOK: Tratamento de Alerta de Memória Alta (Chronos API)

* **Serviço**: Chronos API
* **Severidade**: CRITICAL
* **SLA de Resolução**: 15 minutos (comercial) | 30 minutos (fora do horário comercial)
* **Namespace**: `production`
* **Canal de Escalação**: `@chronos-core` (Slack)

---

### ### PASSO 1: Verificação Inicial de Status (Tempo Estimado: 2 min)

O primeiro passo consiste em identificar o estado geral dos pods da aplicação no cluster EKS para verificar se há falhas catastróficas ou reinicializações em andamento.

1. Execute o comando abaixo para listar os pods do Chronos API no namespace de produção:
   `kubectl get pods -n production -l app=chronos-api`

2. **Verificação Esperada**:
   * O HPA deve manter pelo menos 6 réplicas ativas sob carga normal.
   * Observe a coluna **STATUS** e **RESTARTS**.
   * *Exemplo de Output Saudável*: `chronos-api-7d4f9b8c-abc12  1/1  Running  0  4h`
   * *Exemplo de Alerta*: Se houver pods com status `CrashLoopBackOff`, `OOMKilled` ou com número de `RESTARTS` maior que 0, o container já está sofrendo reinicializações por falta de memória.

3. **O que fazer se houver pods em erro**:
   * Se o status for `OOMKilled`, pule imediatamente para o **PASSO 4 (Análise de Logs)** e **PASSO 6 (Ações Corretivas)** para mitigar o impacto antes que o cluster inteiro seja afetado.

---

### ### PASSO 2: Análise de Memória em Tempo Real (Tempo Estimado: 2 min)

Precisamos validar se o alerta de memória alta (>85%) condiz com o estado atual do cluster ou se é um falso positivo do sistema de monitoramento.

1. Verifique o consumo real de recursos (CPU e Memória) de cada pod ativo:
   `kubectl top pods -n production -l app=chronos-api`

2. **Verificação Esperada**:
   * Compare o consumo reportado em MiB/GiB com os limites configurados no manifesto da aplicação.
   * Se o limite do container for de `1Gi` (1024Mi) e o consumo estiver acima de `870Mi`, o pod está operando na zona crítica de disparo do alerta.

3. **O que fazer se a memória estiver alta**:
   * Se todos os pods apresentarem consumo uniformemente alto, temos um aumento real de tráfego ou um vazamento de memória (*memory leak*) global.
   * Se apenas um ou dois pods estiverem com consumo alto enquanto os outros estão normais, o tráfego pode estar mal distribuído ou um processo específico travou nesses containers. Prossiga para o diagnóstico de dependências.

---

### ### PASSO 3: Verificação de Dependências (Tempo Estimado: 2 min)

Problemas de lentidão ou travamento nas dependências (banco de dados ou filas) costumam represas requisições na API, gerando acúmulo de objetos na memória RAM do Node.js.

1. **Validar conexão com o Ledger (PostgreSQL)**:
   Rode um teste de conexão rápido a partir de um dos pods ativos para garantir que o banco está respondendo:
   `kubectl exec -it deployment/chronos-api -n production -c chronos-api -- pg_isready -h ledger-db.internal.hvt.io -p 5432`
   * *Output Esperado*: `ledger-db.internal.hvt.io:5432 - accepting connections`
   * *Se falhar*: O banco de dados está fora do ar ou recusando conexões (pool esgotado). Pule para o **PASSO 7 (Escalação)**.

2. **Validar status do Reactor (Filas SQS)**:
   Verifique se há um represamento incomum de mensagens na fila do Reactor, o que indica que a API não está conseguindo processar ou despachar tarefas:
   `aws sqs get-queue-attributes --queue-url https://sqs.us-east-1.amazonaws.com/123456789012/reactor-queue --attribute-names ApproximateNumberOfMessages --region us-east-1`
   * *Verificação*: Se o número de mensagens pendentes (`ApproximateNumberOfMessages`) estiver anormalmente alto (ex: > 50.000), a API está sobrecarregada tentando consumir a fila.

---

### ### PASSO 4: Análise de Logs no Beacon (Tempo Estimado: 2 min)

O Beacon centraliza os logs de produção. Devemos buscar padrões de erro específicos que expliquem o consumo de memória.

1. Caso prefira o terminal para uma análise rápida, execute:
   `kubectl logs -n production -l app=chronos-api --tail=200 | grep -iE "oom|memory|leak|pool|timeout"`

2. **Palavras-chave a procurar**:
   * `JavaScript heap out of memory`: Confirmação direta de estouro de memória do Node.js.
   * `Connection pool exhausted` ou `Timeout acquiring connection`: Indica que a API está travada esperando o banco Ledger, acumulando requisições na memória.
   * `FATAL ERROR: Ineffective mark-compacts near heap limit Allocation failed`: Indica falha severa do Garbage Collector (GC).

3. **O que fazer**:
   * Se encontrar `heap out of memory` de forma recorrente em pods recém-iniciados, trata-se de um **Memory Leak** ativo introduzido por algum deploy recente. Vá para o **PASSO 6** para reiniciar os pods e prepare a escalação.

---

### ### PASSO 5: Análise de Métricas no Grafana (Tempo Estimado: 2 min)

Acesse o Grafana para analisar o comportamento histórico do consumo de memória e a atividade do Garbage Collector.

1. Abra o dashboard **Chronos API - Main** e localize a seção **Node.js Runtime Metrics**.
2. **Métricas a observar**:
   * **Memory Usage Trend (Heap Used vs Heap Total)**: Se a linha de memória usada cresce continuamente em formato de "dente de serra" sem nunca retornar ao patamar inicial após a execução do Garbage Collector, há um vazamento de memória (*memory leak*).
   * **GC Frequency & Duration**: Se a frequência de Garbage Collection está altíssima e o tempo de pausa está subindo, o processo está gastando mais tempo tentando liberar memória do que processando requisições.
3. **O que fazer**:
   * Se a tendência for estritamente crescente e linear, o reinício dos pods será apenas uma solução temporária. Prossiga para as ações corretivas imediatas para ganhar tempo e acione o time especialista.

---

### ### PASSO 6: Ações Corretivas Imediatas (Tempo Estimado: 3 min)

Estas ações visam mitigar o impacto para o usuário final de forma imediata enquanto a causa raiz é investigada.

1. **Ação 1: Restart Gradual dos Pods (Estratégia de Alívio)**:
   Se a memória estiver no limite e o serviço lento, force um restart controlado para liberar a memória acumulada sem causar indisponibilidade:
   `kubectl rollout restart deployment/chronos-api -n production`
   * *Tempo de validação*: 2 minutos. Monitore se os novos pods sobem com consumo de memória baixo.

2. **Ação 2: Escalar a Quantidade Mínima de Réplicas no HPA**:
   Se o tráfego estiver muito alto, force o HPA a manter mais réplicas ativas para distribuir a carga de memória entre mais instâncias:
   `kubectl patch hpa chronos-api -n production -p '{"spec":{"minReplicas":8}}'`
   * *Efeito*: O Kubernetes subirá imediatamente mais 2 pods (subindo o mínimo de 6 para 8), aliviando a pressão individual de cada container.

3. **Ação 3: Verificar Deploys Ativos no Argo CD**:
   Verifique se houve alguma alteração recente no código que possa ter introduzido o bug:
   `argocd app get chronos-api`
   * *Verificação*: Se houver um deploy realizado nas últimas horas, verifique o commit correspondente. Se o problema começou exatamente após o deploy, avalie junto ao time a necessidade de um Rollback imediato via Argo CD.

---

### ### PASSO 7: Critérios de Escalação (Imediato se aplicável)

Você deve acionar o time especialista **`@chronos-core`** no Slack se encontrar qualquer um dos cenários abaixo:

1. **Cenários de Escalação**:
   * O restart dos pods (Ação 1) não resolveu e a memória voltou a subir para >85% em menos de 5 minutos (forte indício de Memory Leak crítico).
   * O banco de dados Ledger está fora do ar ou com conexões esgotadas e as ações locais não surtiram efeito.
   * Múltiplos pods estão entrando em loop de restart por `OOMKilled` simultaneamente.
   * O incidente não foi mitigado após 10 minutos do início do diagnóstico.

2. **Template de Mensagem para o Slack (`#oncall-chronos`)**:
   > **🚨 ESCALAÇÃO DE INCIDENTE: Chronos API - Memória Alta**
   > * **Status atual**: Memória em >85% nos pods da API, gerando lentidão.
   > * **Ações executadas**: Executado `rollout restart` e escalado HPA mínimo para 8 réplicas.
   > * **Diagnóstico inicial**: Identificado padrão de `heap out of memory` nos logs após o deploy da versão `v1.2.4`. Conexão com Ledger e Reactor está normal.
   > * **Apoio necessário**: Solicito apoio do time `@chronos-core` para analisar possível vazamento de memória no commit do último deploy.

---

### ### PASSO 8: Encerramento do Incidente (Tempo Estimado: 5 min)

Após a estabilização dos serviços, siga o protocolo de fechamento:

1. **Validação de Estabilidade**:
   Monitore o consumo de memória via `kubectl top pods` por no mínimo 5 minutos após a última ação corretiva. Garanta que a curva de consumo no Grafana estabilizou abaixo de 70%.
2. **Comunicação**:
   Informe no canal `#oncall-chronos` do Slack que o incidente foi mitigado e o sistema está operando normalmente.
3. **Pós-Incidente**:
   Abra um ticket no Jira (projeto `CHRONOS`) com a tag `post-mortem` detalhando:
   * Horário de início e fim do alerta.
   * Comandos executados e impacto gerado.
   * Causa raiz identificada (ex: vazamento de memória no endpoint `/v1/process`).
   * Ações preventivas recomendadas (ex: ajuste de limits/requests de memória ou otimização de queries).