---

# # Relatório Executivo de Otimização de Custos AWS (FinOps)

**Para**: Goldie e Diretoria da Hill Valley Tech  
**De**: Consultoria de FinOps e Arquitetura Cloud  
**Objetivo**: Redução de 15% nos custos AWS até o fim do próximo trimestre, com preservação absoluta de SLAs de produção.

---

## ## 1. Resumo Executivo

Este relatório apresenta o planejamento estratégico para atingir a meta corporativa de **15% de redução** nos custos de infraestrutura AWS da Hill Valley Tech até o final do próximo trimestre. 

Atualmente, a nossa conta consolidada apresenta um custo mensal de `$41.800`. A meta de 15% exige uma redução recorrente de pelo menos `$6.270/mês`, estabelecendo um teto de gastos de `$35.530/mês`. 

Após uma análise detalhada de telemetria e faturamento, identificamos oportunidades que somam uma economia recorrente de **`$6.880/mês`** (equivalente a uma redução de **16,5%** sobre o custo total). O grande diferencial deste plano é que as maiores economias são obtidas por meio de otimizações de faturamento e ciclo de vida de dados, garantindo que a alta disponibilidade (Multi-AZ), a redundância e a performance das aplicações em produção permaneçam **100% inalteradas**.

As fórmulas de consolidação financeira utilizadas para este planejamento são apresentadas a seguir:

$$\text{Custo Mensal Atual} = \$41.800$$

$$\text{Meta de Redução (15\%)} = \$41.800 \times 0,15 = \$6.270$$

$$\text{Economia Total Proposta} = \$6.880 \quad (16,5\% \text{ de redução})$$

---

## ## 2. Análise de Risco e Pré-requisitos

Para garantir que nenhuma das medidas de otimização degrade a performance ou a disponibilidade dos sistemas, mapeamos as seguintes mitigações e pré-requisitos técnicos:

### ### A. Preservação de SLA no Banco de Dados (RDS)
* **Risco**: O banco de dados PostgreSQL de produção opera em arquitetura Multi-AZ, o que é essencial para o SLA de alta disponibilidade e failover automático.
* **Mitigação**: A oportunidade mapeada para o RDS é estritamente financeira (compra de *Reserved Instances* de 1 ano, modalidade *No Upfront*). Não há qualquer alteração de infraestrutura, modificação de tamanho de instância ou downtime associado. O SLA de banco de dados permanece intacto.

### ### B. Rightsizing de Computação (EC2 On-Demand)
* **Risco**: Reduzir a capacidade de instâncias com base em médias de utilização pode gerar gargalos de CPU ou memória durante picos sazonais de tráfego.
* **Mitigação & Pré-requisitos**: Antes de aplicar qualquer alteração de tamanho (*rightsizing*), deve-se analisar o histórico de métricas do *AWS Compute Optimizer* por um período mínimo de 14 dias corridos. O redimensionamento deve priorizar instâncias de workloads variáveis que operam com média histórica de utilização abaixo de 45%. Após o ajuste, o saldo remanescente estável será coberto por um *Compute Savings Plan* de 1 ano para garantir flexibilidade entre famílias de instâncias.

### ### C. Retenção de Logs e Compliance (CloudWatch)
* **Risco**: Reduzir a retenção de logs do CloudWatch pode violar requisitos de conformidade, auditoria de segurança ou dificultar a investigação de incidentes passados.
* **Mitigação**: A retenção padrão no CloudWatch será reduzida de 90 para 30 dias (suficiente para a maior parte das investigações operacionais). Como pré-requisito, será configurada uma política de ciclo de vida para exportar automaticamente os logs frios (com mais de 30 dias) para um bucket S3 Standard-IA ou Glacier Instant Retrieval, mantendo a conformidade com um custo até 80% menor por GB armazenado.

### ### D. Latência de Armazenamento (S3)
* **Risco**: A movimentação de arquivos entre camadas de armazenamento pode introduzir latência de recuperação ou custos inesperados de transição.
* **Mitigação**: A ativação do *S3 Intelligent-Tiering* não altera a performance de acesso aos dados (as camadas de acesso frequente e infrequente possuem a mesma latência de milissegundos do S3 Standard) e não cobra taxas de recuperação, tornando a transição totalmente segura para os 5 buckets principais de produção.

---

## ## 3. Recomendações para Atingir a Meta de 15%

Para garantir uma transição suave e controlada, propomos um roadmap de implementação dividido em três fases ao longo do trimestre:

### ### Fase 1: Otimizações Financeiras (Mês 1) - "Quick Wins"
Foco em ações de faturamento que não exigem alterações de código ou infraestrutura, garantindo impacto financeiro imediato com risco operacional nulo.
1. **Adesão a RDS Reserved Instances (RI)**: Adquirir reserva de 1 ano na modalidade *No Upfront* para o banco PostgreSQL de produção.
2. **Adesão a ElastiCache Reserved Nodes**: Adquirir reserva de 1 ano para o cluster de Redis de produção.
3. **Ativação do S3 Intelligent-Tiering**: Habilitar a regra nos 5 buckets principais para iniciar a análise de padrões de acesso.

### ### Fase 2: Ajustes de Configuração e Políticas (Mês 2)
Foco em otimizações de armazenamento e observabilidade que exigem pequenas alterações de configuração de console ou IaC.
1. **Ajuste de Retenção do CloudWatch Logs**: Alterar o tempo de retenção padrão de 90 para 30 dias e implementar o fluxo de arquivamento para S3.
2. **Limpeza de Métricas Inativas**: Revisar e desativar métricas customizadas do CloudWatch que não estão associadas a alarmes ativos ou dashboards de produção.

### ### Fase 3: Rightsizing e Savings Plans (Mês 3)
Foco em computação e workloads variáveis, exigindo validação de telemetria e coordenação com os times de engenharia.
1. **Rightsizing de instâncias EC2 On-Demand**: Executar o downsizing de instâncias superdimensionadas identificadas pelo *Compute Optimizer*.
2. **Assinatura de Compute Savings Plans**: Contratar o plano de computação de 1 ano para cobrir o baseline de uso estável das instâncias EC2 remanescentes.

---

## ## 4. Conclusão para a Diretoria

A meta de redução de custos de 15% (`$6.270/mês`) é plenamente viável e pode ser superada de forma segura e estruturada. Ao combinar otimizações puramente financeiras (reservas de banco de dados e cache) com ajustes finos de retenção de logs, armazenamento inteligente e redimensionamento de computação ociosa, a **Hill Valley Tech** alcançará uma economia recorrente de **`$6.880/mês`** (redução real de **16,5%**).

O principal diferencial deste plano é o **risco operacional praticamente nulo**: as maiores fatias de economia vêm de compromissos de faturamento (RDS e ElastiCache) e automação de ciclo de vida de dados (S3), mantendo intactos todos os mecanismos de alta disponibilidade (Multi-AZ), redundância e tempos de resposta exigidos pelos nossos clientes. 

Recomendamos o início imediato da **Fase 1** na próxima janela de faturamento para capturar os primeiros ganhos financeiros de forma imediata.