# Q03 - Relatório de Redução de Custos Cloud | Prompt T-A-G

Aja como um consultor sênior de FinOps e arquitetura cloud, com foco em redução de custos AWS sem degradar SLA.

Tarefa:
A partir do CSV real de custos abaixo, produza um relatório executivo em português para a diretoria, alinhado à meta de 15% de redução no custo cloud até o fim do próximo trimestre, sem degradar SLA.

Use o framework T-A-G da seguinte forma:
1. Tarefa: identificar oportunidades de economia
2. Análise: interpretar o CSV, estimar impacto financeiro e priorizar iniciativas
3. Geração: redigir o relatório com recomendações acionáveis

Requisitos do relatório:
1. Priorize as oportunidades de economia por maior impacto financeiro.
2. Para cada oportunidade, informe obrigatoriamente:
   - descrição da ação
   - estimativa de economia mensal em USD
   - percentual que a economia representa sobre a conta total
   - esforço de implementação: baixo, médio ou alto
   - riscos, trade-offs e pré-requisitos
3. Inclua uma conclusão indicando quais medidas, combinadas, podem atingir ou se aproximar da meta de 15%.
4. Não crie dados fictícios: use apenas os valores do CSV e inferências razoáveis baseadas neles.
5. Preserve o SLA como restrição obrigatória: qualquer recomendação deve considerar risco operacional, disponibilidade e desempenho.
6. Se houver ambiguidades ou limitações nos dados, explicite-as de forma objetiva.
7. Estruture a saída em seções claras, com foco executivo e linguagem direta.

CSV de custos:
servico,categoria,custo_mensal_usd,uso_medio_pct,observacao
EC2 reservada,compute,4200,72,contrato de 1 ano
EC2 on-demand,compute,8200,45,workloads variaveis
EKS,compute,6700,58,3 clusters
RDS PostgreSQL,databases,8200,62,multi-AZ
ElastiCache Redis,databases,2100,40,cluster de producao
S3 Standard,storage,3100,,5 buckets principais
EBS gp3,storage,1600,68,volumes de producao
CloudWatch Logs,observability,2800,,retencao de 90 dias
CloudWatch Metrics,observability,900,,
Data Transfer Out,network,1900,,trafego entre regioes
NAT Gateway,network,1200,,3 gateways ativos
Lambda,compute,900,30,~12M invocacoes/mes

Formato de saída:
- Resumo executivo
- Tabela de oportunidades priorizadas
- Análise de risco e pré-requisitos
- Recomendações para atingir a meta de 15%
- Conclusão para a diretoria

Se possível, apresente os valores com arredondamento simples e mantenha o texto pronto para apresentação à Goldie e à diretoria.