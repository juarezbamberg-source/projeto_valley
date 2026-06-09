# RELATÓRIO EXECUTIVO DE OTIMIZAÇÃO DE CUSTOS AWS
## FinOps – Redução de 15% sem Degradação de SLA

---

## RESUMO EXECUTIVO

**Custo mensal atual:** USD 41.700  
**Meta de redução:** 15% (USD 6.255/mês)  
**Oportunidades identificadas:** 8 iniciativas viáveis  
**Economia potencial combinada:** USD 7.840/mês (18,8%)  
**Prazo de implementação:** 90 dias

A análise do portfólio AWS revela **oportunidades de economia de USD 7.840 mensais** através de otimizações de compute, observability e network, atingindo **18,8% de redução** sem comprometer SLA. As três iniciativas de maior impacto (EC2 on-demand → Reserved Instances, EKS consolidação e CloudWatch Logs retenção) respondem por **USD 5.640 (71,9%)** da economia total.

**Recomendação:** Implementar as 5 iniciativas de baixo/médio esforço (USD 6.540) nos próximos 60 dias garante atingir a meta com margem de segurança.

---

## TABELA DE OPORTUNIDADES PRIORIZADAS---

## DETALHAMENTO DAS OPORTUNIDADES

### 1️⃣ EC2 on-demand → Reserved Instances (1-3 anos)
**Economia:** USD 2.870/mês | **6,9% da conta**

**Descrição:**  
Converter workloads variáveis (EC2 on-demand, USD 8.200/mês, 45% utilização) para Reserved Instances (RI) de 1 ou 3 anos. Com 45% de utilização média, há espaço para RI sem risco de subutilização.

**Cálculo:**
- Custo on-demand anual: USD 98.400
- RI 1-ano (35% desconto): USD 63.960 → economia USD 34.440/ano = **USD 2.870/mês**
- RI 3-anos (50% desconto): USD 49.200 → economia USD 49.200/ano = **USD 4.100/mês** (mais agressivo)

**Esforço:** Médio (análise de padrões, compra de RI, ajuste de ASG)  
**Risco SLA:** Baixo (RI não afeta performance; apenas modelo de cobrança)  
**Pré-requisitos:**
- Validar padrão de uso nos últimos 90 dias (CloudTrail/Cost Explorer)
- Confirmar que 45% é baseline, não pico sazonal
- Manter 10-15% de on-demand para elasticidade

**Trade-offs:**
- Comprometimento de capital por 1-3 anos
- Menor flexibilidade para reduzir instâncias
- Recomendação: RI 1-ano como primeira onda; 3-anos após validação de estabilidade

---

### 2️⃣ Consolidar EKS: 3 clusters → 2 clusters
**Economia:** USD 2.010/mês | **4,8% da conta**

**Descrição:**  
Reduzir de 3 clusters EKS (USD 6.700/mês, 58% utilização) para 2 clusters usando namespaces e RBAC para isolamento lógico. Elimina overhead de control plane redundante.

**Cálculo:**
- Custo por cluster EKS: ~USD 2.233/mês (USD 6.700 ÷ 3)
- Consolidação 3→2: elimina 1 control plane = **USD 2.010/mês**
- Redução de worker nodes: ~10-15% (melhor bin-packing)

**Esforço:** Alto (migração de workloads, testes de isolamento, validação de rede)  
**Risco SLA:** Médio
- Risco: falha de um cluster afeta 2 namespaces vs. 1 antes
- Mitigação: implementar Pod Disruption Budgets, anti-affinity rules, backup de etcd

**Pré-requisitos:**
- Mapeamento de workloads por cluster (qual aplicação está onde)
- Validar que 58% de utilização permite consolidação sem throttling
- Plano de migração com janela de manutenção

**Trade-offs:**
- Aumento de complexidade operacional (mais namespaces, mais RBAC)
- Risco de "noisy neighbor" (um workload impacta outro)
- Recomendação: implementar Network Policies e Resource Quotas rigorosos

---

### 3️⃣ CloudWatch Logs: reduzir retenção 90 → 30 dias
**Economia:** USD 1.760/mês | **4,2% da conta**

**Descrição:**  
Reduzir período de retenção de logs de 90 para 30 dias (USD 2.800/mês). Logs antigos são arquivados em S3 (custo negligenciável) para auditoria.

**Cálculo:**
- Custo atual: USD 2.800/mês (90 dias)
- Custo com 30 dias: ~USD 1.040/mês
- Economia: **USD 1.760/mês** (62,9% redução)

**Esforço:** Baixo (mudança de configuração, setup de S3 export)  
**Risco SLA:** Baixo
- Logs ainda disponíveis em S3 para troubleshooting histórico
- Impacto zero em performance/disponibilidade

**Pré-requisitos:**
- Validar conformidade regulatória (LGPD, SOX, etc.)
- Configurar S3 Lifecycle para arquivamento automático
- Testar restore de logs do S3 (validar processo)

**Trade-offs:**
- Latência aumentada para acessar logs > 30 dias (S3 vs. CloudWatch)
- Recomendação: manter 90 dias apenas para logs críticos (segurança, auditoria); 30 dias para aplicação

---

### 4️⃣ ElastiCache: otimizar node type (40% → 60% uso)
**Economia:** USD 630/mês | **1,5% da conta**

**Descrição:**  
Cluster Redis em produção com 40% utilização (USD 2.100/mês). Downsize para node type menor ou consolidar shards.

**Cálculo:**
- Utilização atual: 40% (subutilizado)
- Downsize estimado: 30% redução de custo = **USD 630/mês**
- Novo custo: ~USD 1.470/mês

**Esforço:** Médio (teste de performance, validação de latência, failover)  
**Risco SLA:** Médio
- Risco: menor headroom para picos de tráfego
- Mitigação: monitorar CloudWatch Metrics (CPU, evictions); alertas em 70% utilização

**Pré-requisitos:**
- Análise de padrão de acesso (picos vs. baseline)
- Teste em staging com carga realista
- Plano de rollback (upgrade rápido se necessário)

**Trade-offs:**
- Menor margem para crescimento de tráfego
- Recomendação: implementar auto-scaling ou cache warming antes de downsize

---

### 5️⃣ Data Transfer Out: usar CloudFront + S3 regional
**Economia:** USD 570/mês | **1,4% da conta**

**Descrição:**  
Tráfego entre regiões (USD 1.900/mês) pode ser reduzido com CloudFront (cache) e replicação S3 regional inteligente.

**Cálculo:**
- Data Transfer Out atual: USD 1.900/mês
- CloudFront reduz egress ~30% (cache hit rate típico 60-70%)
- Economia: **USD 570/mês** (30% redução)
- Custo CloudFront: ~USD 150/mês (offset parcial)

**Esforço:** Médio (configurar CloudFront, validar cache headers, teste de latência)  
**Risco SLA:** Baixo
- CloudFront melhora latência (benefício adicional)
- Risco: cache stale se TTL mal configurado

**Pré-requisitos:**
- Identificar quais buckets S3 servem tráfego inter-região
- Validar que conteúdo é cacheable (não dinâmico)
- Configurar cache invalidation strategy

**Trade-offs:**
- Custo CloudFront (~USD 150/mês) reduz economia líquida
- Recomendação: priorizar para conteúdo estático (assets, imagens)

---

### 6️⃣ RDS: avaliar downsize ou Aurora (multi-AZ)
**Economia:** USD 410/mês | **1,0% da conta**

**Descrição:**  
RDS PostgreSQL multi-AZ (USD 8.200/mês, 62% utilização) pode ser downsized ou migrado para Aurora (mais eficiente).

**Cálculo:**
- Downsize de instance type: ~5% redução = USD 410/mês
- OU migração Aurora: ~20% redução, mas requer validação de compatibilidade

**Esforço:** Alto (downtime, testes de performance, validação de aplicação)  
**Risco SLA:** Alto
- Risco: downsize pode causar CPU throttling, impactando aplicação
- Risco Aurora: compatibilidade de driver, comportamento transacional diferente

**Pré-requisitos:**
- Análise detalhada de workload (IOPS, CPU, memória)
- Teste em staging com carga realista
- Plano de rollback (upgrade rápido)
- Backup completo antes de migração

**Trade-offs:**
- Downsize: menor headroom, risco de performance degradation
- Aurora: maior complexidade operacional, mas melhor custo-benefício a longo prazo
- Recomendação: **não priorizar** neste trimestre; avaliar para Q2 2026

---

### 7️⃣ NAT Gateway: consolidar 3 → 2 gateways
**Economia:** USD 400/mês | **1,0% da conta**

**Descrição:**  
3 NAT Gateways ativos (USD 1.200/mês) podem ser consolidados para 2 com roteamento inteligente.

**Cálculo:**
- Custo por NAT Gateway: ~USD 400/mês (USD 1.200 ÷ 3)
- Consolidação 3→2: elimina 1 gateway = **USD 400/mês**

**Esforço:** Baixo (mudança de route table, validação de failover)  
**Risco SLA:** Baixo
- Risco: falha de 1 NAT afeta 2 AZs vs. 1 antes
- Mitigação: monitorar NAT Gateway metrics (bytes/packets); alertas em 80% utilização

**Pré-requisitos:**
- Validar distribuição de tráfego entre AZs
- Confirmar que 2 NAT Gateways suportam pico de tráfego
- Teste de failover

**Trade-offs:**
- Menor redundância (2 vs. 3 AZs)
- Recomendação: manter 3 se aplicação é crítica; consolidar para 2 se tolerância a falha é aceitável

---

### 8️⃣ Lambda: otimizar memória e duração (30% → 50% uso)
**Economia:** USD 270/mês | **0,6% da conta**

**Descrição:**  
Lambda com 30% utilização (USD 900/mês, ~12M invocações/mês). Otimizar código e alocação de memória.

**Cálculo:**
- Custo atual: USD 900/mês
- Otimização (reduzir duração 20%, reduzir memória 10%): ~30% redução = **USD 270/mês**

**Esforço:** Baixo (code review, profiling, testes)  
**Risco SLA:** Baixo
- Risco: otimização agressiva pode aumentar latência
- Mitigação: monitorar CloudWatch Metrics (duration, errors)

**Pré-requisitos:**
- Análise de CloudWatch Logs (duração média, P99)
- Profiling de código (identificar gargalos)
- Teste de carga antes/depois

**Trade-offs:**
- Nenhum significativo; otimização pura
- Recomendação: implementar como parte de DevOps contínuo

---

## ANÁLISE DE RISCO E PRÉ-REQUISITOS

### Matriz de Risco SLA

| Iniciativa | Risco | Mitigação | Prioridade |
|---|---|---|---|
| **EC2 RI** | Baixo | Validar padrão de uso; manter 10-15% on-demand | 🔴 P1 |
| **EKS consolidação** | Médio | Pod Disruption Budgets, Network Policies, anti-affinity | 🟡 P2 |
| **CloudWatch retenção** | Baixo | Arquivar em S3; validar conformidade | 🔴 P1 |
| **ElastiCache downsize** | Médio | Monitorar CPU/evictions; alertas em 70% | 🟡 P2 |
| **Data Transfer CloudFront** | Baixo | Validar cache headers; TTL apropriado | 🔴 P1 |
| **RDS downsize/Aurora** | Alto | Teste em staging; plano de rollback | 🟢 P3 |
| **NAT consolidação** | Baixo | Teste de failover; monitorar utilização | 🔴 P1 |
| **Lambda otimização** | Baixo | Profiling; monitorar latência | 🔴 P1 |

### Pré-requisitos Globais

1. **Governança de Custos**
   - Implementar AWS Cost Anomaly Detection
   - Configurar Budget Alerts em USD 41.700 (baseline)
   - Revisar mensalmente (Cost Explorer)

2. **Observability**
   - CloudWatch Dashboards para cada iniciativa
   - Alertas em SLA críticos (latência, erro rate, disponibilidade)
   - Baseline de performance antes de mudanças

3. **Processo de Mudança**
   - Change Advisory Board (CAB) para iniciativas P2/P3
   - Janelas de manutenção aprovadas
   - Plano de rollback documentado

4. **Validação de Conformidade**
   - Revisar LGPD/SOX para retenção de logs
   - Validar SLA contratual (RTO/RPO)
   - Documentar trade-offs aprovados

---

## RECOMENDAÇÕES PARA ATINGIR A META DE 15%

### Cenário 1: Conservador (Baixo Risco) – USD 6.540/mês (15,7%)

**Implementar em 60 dias:**
1. ✅ EC2 on-demand → RI 1-ano: **USD 2.870**
2. ✅ CloudWatch Logs 90→30 dias: **USD 1.760**
3. ✅ Data Transfer CloudFront: **USD 570**
4. ✅ NAT Gateway 3→2: **USD 400**
5. ✅ Lambda otimização: **USD 270**
6. ✅ ElastiCache downsize: **USD 630**

**Total:** USD 6.540/mês | **15,7% redução** ✅ Meta atingida

**Risco:** Baixo | **Esforço:** 2 médios + 4 baixos | **Prazo:** 60 dias

---

### Cenário 2: Agressivo (Médio Risco) – USD 8.550/mês (20,5%)

**Implementar em 90 dias:**
1. ✅ EC2 on-demand → RI 1-ano: **USD 2.870**
2. ✅ EKS consolidação 3→2: **USD 2.010**
3. ✅ CloudWatch Logs 90→30 dias: **USD 1.760**
4. ✅ Data Transfer CloudFront: **USD 570**
5. ✅ NAT Gateway 3→2: **USD 400**
6. ✅ Lambda otimização: **USD 270**
7. ✅ ElastiCache downsize: **USD 630**

**Total:** USD 8.550/mês | **20,5% redução** ✅ Meta superada

**Risco:** Médio | **Esforço:** 1 alto + 2 médios + 4 baixos | **Prazo:** 90 dias

---

### Cenário 3: Máximo (Alto Risco) – USD 8.960/mês (21,5%)

**Implementar em 120 dias:**
- Todos os itens do Cenário 2 + RDS downsize: **USD 410**

**Total:** USD 8.960/mês | **21,5% redução**

**Risco:** Alto | **Não recomendado** para este trimestre

---

## ROADMAP DE IMPLEMENTAÇÃO (90 DIAS)

### Semana 1-2: Planejamento e Validação
- [ ] Análise detalhada de padrão EC2 (CloudTrail, Cost Explorer)
- [ ] Mapeamento de workloads EKS
- [ ] Validação de conformidade (logs, retenção)
- [ ] Aprovação CAB

### Semana 3-4: Implementação Baixo Risco
- [ ] Compra de EC2 RI 1-ano (USD 2.870)
- [ ] Redução CloudWatch Logs 90→30 dias (USD 1.760)
- [ ] Configuração CloudFront (USD 570)
- [ ] Consolidação NAT Gateway (USD 400)

### Semana 5-8: Implementação Médio Risco
- [ ] Otimização Lambda (USD 270)
- [ ] Downsize ElastiCache (USD 630)
- [ ] Testes de performance

### Semana 9-12: Implementação Alto Risco (Opcional)
- [ ] Consolidação EKS 3→2 (USD 2.010)
- [ ] Migração/downsize RDS (USD 410)

### Contínuo
- [ ] Monitoramento de SLA (CloudWatch Dashboards)
- [ ] Revisão mensal de custos
- [ ] Ajustes baseados em feedback operacional

---

## CONCLUSÃO PARA A DIRETORIA

### Síntese Executiva

A análise de custos AWS identificou **8 oportunidades viáveis de economia** totalizando **USD 7.840/mês (18,8% redução)**, superando a meta de 15% sem degradar SLA.

**Recomendação:** Implementar o **Cenário 1 (Conservador)** nos próximos 60 dias, garantindo:
- ✅ **Meta atingida:** 15,7% redução (USD 6.540/mês)
- ✅ **Risco baixo:** 6 iniciativas com risco SLA baixo/médio
- ✅ **Prazo realista:** 60 dias para implementação completa
- ✅ **ROI imediato:** economia mensal desde mês 1

### Impacto Financeiro

| Métrica | Valor |
|---|---|
| Custo mensal atual | USD 41.700 |
| Economia mensal (Cenário 1) | USD 6.540 |
| Custo mensal pós-otimização | USD 35.160 |
| Redução percentual | 15,7% |
| Economia anual | USD 78.480 |

### Próximos Passos

1. **Semana 1:** Aprovação de CAB para EC2 RI + CloudWatch Logs
2. **Semana 2-4:** Implementação de iniciativas baixo risco (USD 5.600)
3. **Semana 5-8:** Implementação de iniciativas médio risco (USD 900)
4. **Semana 9+:** Monitoramento contínuo e ajustes

### Riscos Mitigados

- **Conformidade:** Arquivamento de logs em S3 mantém auditoria
- **Performance:** Validação em staging antes de mudanças
- **Disponibilidade:** Redundância mantida (2 NAT vs. 3; 2 EKS clusters vs. 3)
- **Flexibilidade:** 10-15% on-demand mantido para elasticidade

### Recomendação Final

**Aprovar Cenário 1 (Conservador)** como baseline obrigatório. Avaliar Cenário 2 (Agressivo) após 30 dias de monitoramento, caso SLA seja mantido.

---

## LIMITAÇÕES E AMBIGUIDADES DOS DADOS

1. **Utilização (uso_medio_pct):** Valores médios; picos sazonais não capturados
2. **CloudWatch Logs/Metrics:** Sem detalhe de volume (GB/dia); estimativa baseada em retenção padrão
3. **Data Transfer Out:** Sem detalhe de origem/destino; assume tráfego inter-região
4. **RDS:** Sem detalhe de IOPS/storage; downsize estimado conservador
5. **EKS:** Sem detalhe de node types; consolidação assume bin-packing eficiente

**Recomendação:** Validar com dados granulares (CloudTrail, Cost Explorer, CloudWatch Insights) antes de implementação.

---

**Preparado por:** Consultor FinOps Sênior  
**Data:** 6 de setembro de 2026  
**Destinatário:** Diretoria | Goldie  
**Status:** Pronto para apresentação