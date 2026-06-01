# Runbook: Alerta de Memória Alta – Chronos API (Produção)

**Versão:** 1.0  
**SLA:** Resolver em ≤15 min (comercial) / ≤30 min (fora comercial)  
**Ferramentas:** Beacon, Grafana, Slack, `kubectl`, `aws cli`, `argocd cli`  
**Aplicação:** Chronos API | **Namespace:** `production` | **HPA:** min 4, max 12, CPU target 70%

---

## PASSO 1: Verificação Inicial de Status (estimado: 1 min)

**Comando:**
```bash
kubectl get pods -n production -l app=chronos-api -o wide
```

**Verificação esperada:**
- Total de pods rodando, dentro do range do HPA.
- Coluna `STATUS` deve conter apenas `Running`.
- Se houver pods com `CrashLoopBackOff`, `Error` ou `OOMKilled`, anote os nomes.

**O que fazer se houver pods em erro:**
- Se forem até 2 pods, anote os nomes e prossiga para o Passo 2.
- Se mais de 2 pods estiverem com erro, escale imediatamente.

**Exemplo de output esperado:**
```text
NAME                          READY   STATUS    RESTARTS   AGE
chronos-api-7f8c9d6b4c-2xqk   1/1     Running   0          15m
chronos-api-7f8c9d6b4c-3abc   1/1     Running   1          10m
chronos-api-7f8c9d6b4c-ab12   1/1     Running   0          20m
chronos-api-7f8c9d6b4c-xy78   1/1     Running   0          12m
```

---

## PASSO 2: Análise de Memória em Tempo Real (estimado: 2 min)

**Comando:**
```bash
kubectl top pods -n production -l app=chronos-api --containers
```

**Verificação esperada:**
- Para cada pod, veja o uso atual de memória.
- Obtenha os limites configurados:
```bash
kubectl describe deployment chronos-api -n production | grep -A10 "Limits"
```
- Normal: uso abaixo de 80% do limite.
- Alto: acima de 80%.
- Crítico: muito próximo do limite ou crescendo rápido.

**O que fazer se a memória estiver realmente alta:**
- Se mais de 3 pods estiverem acima de 80%, vá para o Passo 6.
- Se poucos pods estiverem altos, anote e siga para o Passo 3.

**Exemplo de output esperado:**
```text
POD                       NAME        CPU(cores)   MEMORY(bytes)
chronos-api-7f8c9d6b4c-2xqk   chronos-api   150m         512Mi
chronos-api-7f8c9d6b4c-3abc   chronos-api   200m         750Mi
...
Limits: memory=1Gi
```

---

## PASSO 3: Verificação de Dependências (estimado: 2 min)

### Ledger (PostgreSQL)

**Comando:**
```bash
kubectl get pods -n production -l app=ledger
```

**Verificação esperada:**
- Pod do PostgreSQL com `STATUS=Running` e `READY=1/1`.

**Opcional:**
```bash
kubectl exec -n production deploy/chronos-api -- sh -c "wget -qO- http://ledger-service:5432/health" 2>/dev/null || echo "Falha no health check"
```

**O que fazer:**
- Se o pod não estiver `Running` ou o check falhar, escale imediatamente.

### Reactor (Filas SQS)

**Comando:**
```bash
aws sqs get-queue-attributes --queue-url https://sqs.<region>.amazonaws.com/<account-id>/<reactor-queue> --attribute-names ApproximateNumberOfMessages ApproximateNumberOfMessagesNotVisible
```

Para descobrir a fila:
```bash
aws sqs list-queues --queue-name-prefix reactor
```

**Verificação esperada:**
- `ApproximateNumberOfMessages` baixo.
- `ApproximateNumberOfMessagesNotVisible` também baixo.
- Se houver acúmulo grande, o Reactor pode estar lento.

**O que fazer:**
- Se Ledger ou Reactor estiverem com problema, escale imediatamente.

---

## PASSO 4: Análise de Logs no Beacon (estimado: 3 min)

**Como acessar:**
- Abra o Beacon em: `[link do Beacon]`
- Selecione `chronos-api` e `production`.
- Filtre os últimos 15 minutos com nível `ERROR` ou `WARN`.

**Palavras-chave para procurar:**
- `OOM`, `OutOfMemoryError`, `memory leak`, `connection pool`
- `GC overhead limit exceeded`, `heap space`
- Repetição da mesma stack trace

**Verificação esperada:**
- Se aparecer `OutOfMemoryError` ou `memory leak`, escale.
- Se forem erros transitórios, continue.
- Se não houver sinais suspeitos, vá ao Passo 5.

**Exemplo de log suspeito:**
```text
2025-03-10 14:23:45 ERROR [c.h.chronos.api.Gateway] - java.lang.OutOfMemoryError: Java heap space
    at com.hvt.chronos.service.DataProcessor.process(DataProcessor.java:45)
```

---

## PASSO 5: Análise de Métricas no Grafana (estimado: 3 min)

**Dashboard:**
- `[dashboard do Chronos API]` — seção de memória.

**Métricas a observar:**
- `Memory usage (bytes)`
- `GC frequency`
- `Heap vs non-heap`
- Linha do limite de memória

**Verificação esperada:**
- Uso estável.
- GC dentro do normal.
- Se a memória cresce sem parar mesmo após GC, suspeite de memory leak e escale.
- Se houve pico recente após deploy, siga para o Passo 6.

---

## PASSO 6: Ações Corretivas Imediatas (estimado total: 5 min)

### Ação 1: Restart de um pod
```bash
kubectl delete pod -n production -l app=chronos-api --field-selector=status.phase=Running --max=1
```

**Verificação:**
- Após 30s, rode `kubectl top pods` novamente.
- Se normalizar em 2 min, considere repetir apenas nos pods afetados.

### Ação 2: Trigger manual do HPA para aumentar réplicas
```bash
kubectl patch hpa chronos-api -n production -p '{"spec":{"minReplicas":8,"maxReplicas":12}}'
```

**Verificação:**
- Veja novos pods surgindo com `kubectl get pods -w`.
- Se em 3 min a média cair abaixo de 70%, mantenha.

### Ação 3: Verificar deploy em andamento no Argo CD
```bash
argocd app list | grep chronos-api
argocd app get chronos-api
```

**Verificação esperada:**
- `SYNC STATUS = Synced`
- `HEALTH STATUS = Healthy`

Se houver deploy em andamento, aguarde até 2 min para ver se o pico está relacionado ao rollout.

---

## PASSO 7: Critérios de Escalação

Escale para `@chronos-core` no Slack se qualquer condição ocorrer:

- Memória continua acima de 80% após 10 minutos.
- Encontrar `memory leak` ou `OutOfMemoryError` nos logs.
- Ledger ou Reactor com problema.
- Mais de 2 pods em `OOMKilled`.

**Mensagem de escalação:**
```text
@chronos-core Alerta de memória alta no Chronos API em produção.
Contexto:
- Pods com erro: [lista]
- Dependências: [Ledger OK/FAIL, Reactor OK/FAIL]
- Ações tomadas: restart, aumento de réplicas
- Logs suspeitos: [trecho]
- SLA: [tempo restante]
```

---

## PASSO 8: Encerramento do Incidente (estimado: 2 min)

**Verificação final:**
1. Rode o Passo 2 novamente.
2. Confirme memória abaixo de 70% em todos os pods.
3. Verifique que não houve novos alertas nos últimos 5 minutos.

**Documentação:**
- Registre o que foi feito.
- Registre a causa provável.
- Se houver suspeita de leak, abra ticket para análise profunda.

**Comunicação no Slack:**
```text
Incidente resolvido: alerta de memória alta no Chronos API.
Ações: [restart, ajuste de HPA]
Causa: [descrever]
Monitoramento: memória estabilizada nos últimos 5 min.
Ticket para análise: [link]
```

---

## Resumo Operacional

O caminho é: primeiro checar status e memória dos pods, depois validar Ledger e Reactor.  
Se a memória estiver alta em vários pods, agir rápido com restart e aumento temporário de réplicas.  
Se os logs mostrarem `memory leak` ou `OutOfMemoryError`, escale sem insistir em remediação local.  
Se a tendência no Grafana estiver crescendo continuamente, trate como incidente estrutural.  
Se em 10 minutos não houver normalização, o foco deixa de ser correção local e vira escalação.  
Ao final, documente a causa e avise o time no Slack para evitar recorrência.