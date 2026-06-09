# Prompt de Engenharia de Plataforma: Refatoração do Manifesto Kubernetes (chronos-api)

Atue como um Engenheiro de Plataforma Sênior. Sua tarefa é refatorar o manifesto Kubernetes legado do serviço 'chronos-api' seguindo rigorosamente a estrutura B-A-B (Before-After-Bridge) abaixo.

## BEFORE (Estado Atual - Problemas)
O manifesto atual apresenta os seguintes riscos e ineficiências:
- Apenas 1 réplica (sem alta disponibilidade).
- Imagem utilizando a tag 'latest' (instabilidade em deploys).
- Segredos expostos diretamente em variáveis de ambiente (risco de segurança).
- Ausência de requests/limits de CPU e memória (risco de OOMKill e noisy neighbor).
- Ausência de probes de liveness e readiness (falhas de tráfego).
- Sem securityContext (execução como root).
- Sem estratégia de update definida.
- Falta de labels/annotations de negócio e ServiceAccount dedicada.

## AFTER (Estado Desejado - Solução)
O novo manifesto deve implementar:
- Deployment com 3 réplicas e imagem 'chronos-api:v2.1.0'.
- Secrets via Kubernetes Secret (referenciados via envFrom ou valueFrom).
- Resources: Requests (CPU 250m, Mem 256Mi), Limits (CPU 500m, Mem 512Mi).
- Probes: Liveness (/health) e Readiness (/ready).
- SecurityContext: runAsUser: 1000, runAsNonRoot: true, readOnlyRootFilesystem: true.
- Strategy: RollingUpdate (maxSurge: 1, maxUnavailable: 0).
- Metadados: Labels e Annotations padronizados.
- ServiceAccount: 'chronos-api-sa'.

## BRIDGE (Caminho de Transição)
Forneça um plano de migração em 6 passos para garantir zero downtime:
1. Criação da ServiceAccount e Secrets.
2. Aplicação do novo Deployment em paralelo (Canary).
3. Ajuste do Service para apontar para os novos pods.
4. Remoção do Deployment legado.
5. Comandos kubectl necessários para cada etapa.
6. Procedimento de rollback em caso de falha.

Por favor, gere o manifesto YAML completo e o plano de transição detalhado.