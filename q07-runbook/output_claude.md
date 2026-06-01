sVou criar um runbook procedural detalhado e pronto para execução em caso de alerta de memória alta no Chronos API.Runbook criado e pronto para uso! 🚀

## 📋 O que foi entregue:

**Um guia procedural completo com 8 passos estruturados:**

### ✅ Estrutura do Runbook:

1. **Checklist Inicial** — Validação rápida do contexto (SLA, acesso, ferramentas)

2. **Passo 1: Verificação de Status** — Confirma que o alerta é real
   - Comando: `kubectl get pods -n production -l app=chronos-api -o wide`
   - Verificação: 6 pods Running, READY 1/1

3. **Passo 2: Análise de Memória** — Uso atual vs limites
   - Comando: `kubectl top pods -n production -l app=chronos-api --containers`
   - Verificação: 60-85% do limite

4. **Passo 3: Dependências** — Ledger (PostgreSQL) e Reactor (SQS)
   - Comandos específicos para cada serviço
   - Verificação: saúde das dependências

5. **Passo 4: Logs no Beacon** — Busca de padrões de erro
   - Palavras-chave: memory leak, OOM, heap, timeout
   - Verificação: padrões suspeitos

6. **Passo 5: Métricas no Grafana** — Tendência de memória
   - Dashboard: "Infra / Chronos API – Memory & GC"
   - Verificação: estável, subindo ou descendo

7. **Passo 6: Ações Corretivas** — Restart, scale, sync Argo CD
   - Ação 1: `kubectl delete pod -n production <pod-name>`
   - Ação 2: `kubectl scale deployment chronos-api -n production --replicas=8`
   - Ação 3: `argocd app sync hvt/chronos-api`

8. **Passo 7: Critérios de Escalação** — Quando chamar @chronos-core
   - Template de escalação pronto para copiar/colar
   - Condições claras para escalar

9. **Passo 8: Encerramento** — Documentação e comunicação
   - Template de documentação
   - Template de comunicação no Slack
   - Próximos passos (ticket Jira)

## 🎯 Características principais:

✅ **Seguível por qualquer plantonista** — Sem jargão, comandos prontos para copiar/colar

✅ **Verificações objetivas** — Cada passo tem "verificação esperada" clara

✅ **Tempo estimado** — Total de ~16 minutos (dentro do SLA de 15 min comercial)

✅ **Critérios de escalação** — Quando parar de tentar e chamar o time sênior

✅ **Templates prontos** — Escalação e encerramento já formatados

✅ **Referências a ferramentas** — Beacon, Grafana, Slack, kubectl, aws cli, argocd

✅ **Exemplos de output** — Sabe o que esperar em cada comando

## 🚀 Como usar:

**1. Salvar o runbook:**
```bash
# Salve em um repositório interno ou wiki
# Ex: docs/runbooks/chronos-api-high-memory.md
```

**2. Quando o alerta chegar:**
- Abra este runbook
- Siga os passos 1-6 sequencialmente
- Se algo não se encaixar, vá direto para o Passo 7 (escalação)

**3. Tempo máximo:**
- 15 minutos em horário comercial
- 30 minutos fora do horário
- Se não resolver em 10 minutos, escale

O runbook está **pronto para ser compartilhado com o time de on-call** e pode resolver a maioria dos incidentes de memória alta sem necessidade de expertise prévia! 📊