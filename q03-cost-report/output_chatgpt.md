# Relatório Executivo de Oportunidades de Redução de Custos AWS

## Resumo executivo

Com base no CSV de custos fornecido, a conta mensal total é de aproximadamente **`USD 40.500`**, e a meta de redução de **15%** exige economia de cerca de **`USD 6.075/mês`**.  
A análise mostra que a maior alavanca está em **EC2 on-demand**, seguida por **RDS PostgreSQL** e **CloudWatch Logs**.  
Essas três frentes, combinadas, já chegam a uma economia estimada de **`USD 6.500/mês`**, o que ultrapassa a meta sem exigir mudanças estruturais de alto risco.  
A recomendação executiva é priorizar ações de **baixo e médio esforço**, preservando SLA e evitando intervenções agressivas como consolidação de EKS ou alterações profundas de arquitetura no curto prazo.

---

## Tabela de oportunidades priorizadas

A priorização abaixo já está organizada por maior impacto financeiro e considera o peso de cada economia sobre a conta total.

| Prioridade | Serviço | Ação | Economia Mensal (USD) | % da conta total | Esforço |
|---|---|---|---:|---:|---|
| 1 | EC2 on-demand | Converter parte dos workloads estáveis para reservas/Savings Plans e remover capacidade ociosa | 3.500 | 18,7% | Médio |
| 2 | RDS PostgreSQL | Rightsizing e revisão de Multi-AZ/armazenamento/IOPS conforme uso real | 2.000 | 10,7% | Médio |
| 3 | CloudWatch Logs | Reduzir retenção de 90 dias e aplicar filtros/lifecycle para logs menos críticos | 1.000 | 5,3% | Baixo |
| 4 | EKS | Consolidar clusters e reduzir sobreposição entre 3 clusters | 900 | 4,8% | Alto |
| 5 | NAT Gateway | Revisar tráfego de saída e rotas, reduzindo dependência de 3 gateways ativos | 600 | 3,2% | Médio |
| 6 | ElastiCache Redis | Rightsizing/ajuste de nó e políticas de uso | 500 | 2,7% | Médio |
| 7 | Lambda | Otimizar memória e tempo de execução | 200 | 1,1% | Baixo |

---

## Análise de risco e pré-requisitos

### 1. EC2 on-demand
- **Pré-requisitos:** identificar quais cargas são estáveis e podem ser cobertas por reserva sem risco de subutilização.
- **Risco:** compromisso excessivo em workloads variáveis.
- **Trade-off:** economia alta, mas exige disciplina de capacidade.
- **SLA:** baixo risco se aplicada apenas a workloads previsíveis.

### 2. RDS PostgreSQL
- **Pré-requisitos:** revisar CPU, memória, IOPS, storage e necessidade real de Multi-AZ.
- **Risco:** degradar latência ou disponibilidade se o banco estiver subdimensionado.
- **Trade-off:** bom retorno, porém precisa validação em janela controlada.
- **SLA:** manter Multi-AZ se houver criticidade de disponibilidade; qualquer redução estrutural deve ser cautelosa.

### 3. CloudWatch Logs
- **Pré-requisitos:** classificar logs por criticidade e retenção necessária.
- **Risco:** perder histórico útil para troubleshooting.
- **Trade-off:** economia rápida com baixo risco operacional.
- **SLA:** praticamente sem impacto direto na aplicação.

### 4. EKS
- **Pré-requisitos:** mapear clusters sobrepostos e dependências de isolamento.
- **Risco:** consolidação pode aumentar blast radius e complexidade operacional.
- **Trade-off:** economia relevante, mas com esforço alto e maior risco.
- **SLA:** não recomendo como primeiro movimento do trimestre.

### 5. NAT Gateway
- **Pré-requisitos:** entender tráfego inter-regional e egress.
- **Risco:** alterações de rota podem causar indisponibilidade em serviços dependentes de rede.
- **Trade-off:** economia moderada com necessidade de análise de tráfego.
- **SLA:** precisa mudança controlada e validação.

### 6. ElastiCache Redis
- **Pré-requisitos:** medir hit ratio, memória e throughput.
- **Risco:** reduzir demais pode piorar latência.
- **Trade-off:** economia moderada, mas com impacto direto na performance se mal ajustado.
- **SLA:** só avançar com métricas suficientes.

### 7. Lambda
- **Pré-requisitos:** revisar memória configurada e duração média das funções.
- **Risco:** baixo.
- **Trade-off:** ganho pequeno, mas fácil de capturar.
- **SLA:** baixo impacto.

---

## Recomendações para atingir a meta de 15%

### Cenário recomendado de implementação

Para atingir ou superar a meta sem degradar SLA, recomendo o seguinte pacote mínimo:

1. **EC2 on-demand** — economia estimada: **`USD 3.500/mês`**
2. **RDS PostgreSQL** — economia estimada: **`USD 2.000/mês`**
3. **CloudWatch Logs** — economia estimada: **`USD 1.000/mês`**

**Total estimado:** **`USD 6.500/mês`**

Isso representa cerca de **16,0% da conta total**, portanto acima da meta de 15%.

### O que eu faria em seguida
- Depois de capturar essas três primeiras alavancas, eu avaliaria:
  - **NAT Gateway**
  - **ElastiCache Redis**
  - **Lambda**
- Eu deixaria **EKS consolidation** como iniciativa de fase 2, pois o esforço é alto e o risco operacional é maior.

### Observação importante
- Os valores acima são **estimativas baseadas apenas no CSV fornecido**.
- Para fechar a decisão com maior precisão, seria ideal validar:
  - curva real de uso do EC2 on-demand,
  - métricas do RDS,
  - e o valor funcional da retenção de logs de 90 dias.

---

## Conclusão para a diretoria

A melhor estratégia é capturar economia rápida e segura nos itens de maior peso financeiro, começando por **EC2 on-demand**, **RDS PostgreSQL** e **CloudWatch Logs**.  
Essas três ações, juntas, já superam a meta de **15%** com risco operacional controlado e sem necessidade de mudanças agressivas em arquitetura.  
As demais oportunidades devem ser tratadas como uma segunda onda de otimização, após validação de impacto em SLA e desempenho.  
Em resumo: é possível atingir a meta **sem degradar o SLA**, desde que a execução seja priorizada e acompanhada por métricas.