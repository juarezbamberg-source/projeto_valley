ROLE:
Você é um plantonista do time de SRE/DevOps responsável por responder ao alerta 
recorrente de memória alta no Chronos API. Você pode não ter expertise prévia no 
sistema, mas tem acesso às ferramentas padrão (kubectl, aws cli, argocd cli) e 
precisa resolver o incidente de forma rápida e segura, seguindo um procedimento 
documentado passo a passo.

Seu objetivo é diagnosticar a causa raiz do alerta, executar ações corretivas 
imediatas e, se necessário, escalar para o time sênior (@chronos-core) dentro 
do SLA (15 minutos em horário comercial, 30 minutos fora).

INPUT:
Você recebeu o alerta no Slack (#oncall-chronos):
[CRITICAL] High memory usage on Chronos API pods (>85% for 10min)

Contexto técnico disponível:
- Aplicação: Chronos API
- Ambiente: EKS, namespace production
- Configuração: 6 réplicas com HPA (min 4, max 12, CPU target 70%)
- Deploy: Argo CD a partir do repositório hvt/chronos-api
- Dependências: Ledger (PostgreSQL) e Reactor (filas SQS)
- Observabilidade: métricas em /metrics, logs no Beacon, dashboards em Grafana
- Ferramentas disponíveis: kubectl, aws cli, argocd cli
- Escalação: @chronos-core (SLA: 15min comercial, 30min fora)

STEPS:
Crie um runbook procedural com os seguintes passos de diagnóstico e ação:

**PASSO 1: Verificação Inicial de Status**
- Comando específico para verificar status dos pods do Chronos
- Verificação esperada: quantos pods estão rodando, quantos estão em erro
- O que fazer se houver pods em erro

**PASSO 2: Análise de Memória em Tempo Real**
- Comando específico para verificar uso de memória atual de cada pod
- Verificação esperada: qual é o uso de memória de cada pod
- Limites configurados vs uso atual
- O que fazer se a memória estiver realmente alta

**PASSO 3: Verificação de Dependências**
- Comando específico para verificar status do Ledger (PostgreSQL)
- Comando específico para verificar status do Reactor (filas SQS)
- Verificação esperada: se as dependências estão saudáveis
- O que fazer se alguma dependência estiver com problema

**PASSO 4: Análise de Logs**
- Como acessar logs no Beacon
- Quais palavras-chave procurar (memory leak, OOM, connection pool, etc.)
- Verificação esperada: se há padrões de erro nos logs
- O que fazer se encontrar padrões suspeitos

**PASSO 5: Análise de Métricas em Grafana**
- Dashboard específico a consultar
- Quais métricas observar (memory usage trend, GC frequency, etc.)
- Verificação esperada: se há picos anormais ou tendência crescente
- O que fazer se a tendência for crescente

**PASSO 6: Ações Corretivas Imediatas**
- Ação 1: Restart de um pod (comando específico)
- Ação 2: Trigger manual do HPA para aumentar réplicas (comando específico)
- Ação 3: Verificar se há deploy em andamento no Argo CD
- Verificação esperada: se a memória normalizou após cada ação
- Tempo máximo para cada ação

**PASSO 7: Critérios de Escalação**
- Se após 10 minutos a memória não normalizar → escalar
- Se encontrar padrão de memory leak nos logs → escalar
- Se Ledger ou Reactor estiverem com problema → escalar
- Se houver múltiplos pods em OOM → escalar
- Como escalar: mencionar @chronos-core no Slack com contexto

**PASSO 8: Encerramento do Incidente**
- Verificação final: memória estável por 5 minutos
- Documentação: o que foi feito, qual foi a causa
- Comunicação: informar no Slack que o incidente foi resolvido
- Próximos passos: se necessário, criar ticket para análise profunda

EXPECTATION:
O runbook deve:
- Ser seguível por qualquer plantonista sem expertise prévia
- Incluir comandos específicos e prontos para copiar/colar
- Incluir verificações objetivas ao final de cada passo
- Incluir critérios claros para escalar ou continuar
- Incluir tempo estimado para cada passo
- Incluir exemplos de output esperado
- Incluir referências a ferramentas (Beacon, Grafana, Slack)
- Ser prático e direto, sem jargão desnecessário
- Permitir resolução em menos de 15 minutos (SLA comercial)
- Ser documentado em Markdown com estrutura clara