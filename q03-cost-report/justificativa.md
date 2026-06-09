## 📊 Análise SWOT Comparativa — Propostas de Redução de Custos Cloud

### Hill Valley Tech | Preparado para: Goldie Wilson (CEO) e Doc Brown (CTO)

---

## Resumo Executivo

Três modelos de IA (Gemini, ChatGPT e Claude) receberam o mesmo prompt baseado no framework **T-A-G** para produzir um relatório de redução de custos AWS a partir do CSV fornecido. As propostas geradas apresentam diferenças significativas em escopo, profundidade e abordagem:

| Métrica | Gemini | ChatGPT | Claude |
|---|---|---|---|
| **Custo base identificado** | `$41.800` ✅ | `$40.500` ⚠️ | `$41.700` ✅ |
| **Meta de 15%** | `$6.270` ✅ | `$6.075` ⚠️ | `$6.255` ✅ |
| **Economia proposta** | `$6.880 (16,5%)` | `$6.500 (16,0%)` | **`$7.840 (18,8%)`** |
| **Nº de oportunidades** | 6 | 7 | 8 |
| **Cenários propostos** | 3 fases (roadmap temporal) | 1 pacote core + 2ª onda | 3 cenários (risco vs. esforço) |

A análise a seguir dissecar cada proposta sob a ótica solicitada.

---

## 1. 🔵 Proposta Gemini — Relatório de FinOps Estratégico

### Forças
- **Cálculo de base correto:** Identificou `$41.800` — valor exato da soma do CSV (vs. ChatGPT que errou por `$1.300`)
- **Roadmap temporal claro:** Dividiu a implementação em 3 fases ao longo do trimestre (Mês 1: Quick Wins financeiros → Mês 2: Configuração → Mês 3: Rightsizing)
- **Preservação de SLA robusta:** Dedicou uma seção inteira à análise de risco com mitigações específicas para cada sistema core (Chronos, Ledger, Reactor)
- **Healthcheck do RDS inteligente:** Propõe estritamente RI (*Reserved Instance*) para RDS, sem tocar na arquitetura Multi-AZ — risco operacional **praticamente nulo**
- **Fórmulas financeiras transparentes:** Apresentou os cálculos matemáticos explicitamente (`$41.800 × 0,15 = $6.270`)
- **S3 Intelligent-Tiering:** Abordagem de automação sem risco de latência, sem custos de transição

### Fraquezas
- **Escopo limitado a 6 oportunidades:** Perdeu oportunidades como NAT Gateway, ElastiCache Redis, Lambda e Data Transfer Out
- **Ausência de priorização granular:** Não apresentou tabela priorizada por impacto — as oportunidades são descritas narrativamente dentro das fases
- **Esforço não quantificado:** Não classifica cada oportunidade como baixo/médio/alto esforço de forma explícita
- **Economia total subestimada:** `$6.880` é o menor valor entre as três propostas — deixou `$1.000+` na mesa comparado a Claude
- **Sem métricas percentuais por oportunidade:** Não informa quanto cada ação representa individualmente sobre a conta total

### Oportunidades
- Abordagem de **risco quase zero** é ideal para apresentar a uma CEO conservadora
- Roadmap temporal facilita o acompanhamento por parte do time SRE (Lorraine)
- Pode ser complementada com as oportunidades perdidas em uma segunda iteração

### Ameaças
- **Não atinge a meta se alguma fase atrasar** — o plano depende da execução sequencial das 3 fases
- **Silêncio sobre Data Transfer Out e NAT Gateway:** Deixou de capturar economias de baixo esforço (~`$1.000/mês` combinados)
- Pode ser percebida como "pouco ambiciosa" pela diretoria

---

## 2. 🟡 Proposta ChatGPT — Relatório de Oportunidades Priorizadas

### Forças
- **Priorização clara por impacto:** Tabela com 7 oportunidades ordenadas por economia mensal (EC2 → RDS → CloudWatch → EKS → NAT → ElastiCache → Lambda)
- **Esforço explicitado:** Cada oportunidade vem com nível de esforço (baixo, médio, alto)
- **Pacote core bem definido:** Recomenda explicitamente as 3 primeiras oportunidades como *baseline obrigatório* (EC2 + RDS + CloudWatch = `$6.500/mês`)
- **Transparência nas limitações:** Avisa que os valores são estimativas baseadas apenas no CSV e que precisam de validação com métricas reais
- **% da conta total por oportunidade:** Único modelo que fornece essa métrica individualizada
- **Viabilidade imediata:** As ações prioritárias são de baixo/médio esforço com risco controlado

### Fraquezas
- **Erro no custo base:** Identificou `$40.500` em vez dos `$41.800` reais — diferença de `$1.300` que pode gerar desconfiança da diretoria (Goldie)
- **Análise de risco superficial:** Para cada oportunidade, o campo de risco é genérico (ex: "compromisso excessivo em workloads variáveis" sem métricas)
- **Sem roadmap temporal:** Não propõe cronograma de implementação — apenas lista "o que fazer" sem "quando fazer"
- **Ausência de cenários alternativos:** Oferece apenas um caminho, sem plano B caso alguma ação não seja viável
- **Sem detalhamento de pré-requisitos:** Embora mencione riscos, não aprofunda as mitigações ou dependências

### Oportunidades
- Estrutura de tabela priorizada é a **mais apresentável para a CEO** — clara, direta e orientada a números
- Foco em *quick wins* de baixo esforço (CloudWatch Logs e Lambda) permite capturar economia rapidamente
- Separação entre "onda 1" e "onda 2" é um bom modelo de governança

### Ameaças
- **Erro de `$1.300` no custo base é crítico para credibilidade** — Goldie pode questionar a acurácia de toda a análise
- Proposta de **revisão de Multi-AZ no RDS** sem validação prévia é arriscada para o Ledger (sistema core)
- Não menciona o EKS com cuidado: recomendar consolidação de clusters como prioridade #4 sem análise de isolamento pode aumentar *blast radius*

---

## 3. 🟣 Proposta Claude — Relatório FinOps com Cenários

### Forças
- **Economia mais agressiva:** `$7.840/mês (18,8%)` — maior valor entre as três propostas
- **Três cenários bem definidos:** 
  - **Conservador:** `$6.540` (15,7%) — 60 dias, risco baixo ✅
  - **Agressivo:** `$8.550` (20,5%) — 90 dias, risco médio
  - **Máximo:** `$8.960` (21,5%) — 120 dias, risco alto (não recomendado)
- **Pré-requisitos mais detalhados:** Cada oportunidade inclui cálculos, trade-offs, riscos SLA e recomendações específicas
- **Matriz de risco SLA:** Classifica cada iniciativa como baixo/médio/alto risco com mitigação correspondente
- **Cobertura mais ampla:** 8 oportunidades identificadas — inclui Data Transfer Out (CloudFront) que nenhum outro modelo considerou
- **Roadmap granular por semanas:** Semana 1-2 → Semana 3-4 → Semana 5-8 → Semana 9-12
- **Seção de limitações:** Único modelo que explicitamente lista as ambiguidades e lacunas dos dados

### Fraquezas
- **Subjetividade no cálculo do EKS:** Estima economia de `$2.010/mês` com base em divisão proporcional (`$6.700 ÷ 3`), sem considerar que worker nodes representam a maior parte do custo, não o *control plane*
- **Recomendação de RDS downsize:** Embora classificado como P3 (não prioritário), mencionar downsizing do RDS Multi-AZ como possibilidade pode gerar ruído com Lorraine (SRE)
- **Inclui EKS consolidação como cenário:** Mesmo no cenário agressivo, a consolidação de clusters EKS tem risco operacional médio-alto que pode não valer a pena para sistemas core
- **Complexidade de apresentação:** O relatório é muito extenso — 3 cenários × 8 iniciativas × roadmaps podem sobrecarregar Goldie
- **Cálculo de CloudFront:** Estima economia líquida de `$570` mas reconhece custo de `$150` do CloudFront — economia real seria `$420`

### Oportunidades
- Modelo de **cenários múltiplos** é o melhor formato para apresentação à diretoria — permite que Goldie e Doc decidam juntos o nível de risco aceitável
- Data Transfer Out via CloudFront é uma **oportunidade não explorada** pelos outros modelos e de baixo risco
- A seção de "Limitações e Ambiguidades" demonstra maturidade analítica e transparência

### Ameaças
- **Cenário agressivo pode ser visto como "venda de sonhos"** se não for realista para 90 dias
- Consolidação EKS sem análise de *tenancy model* pode causar incidentes em produção
- A amplitude de 8 iniciativas pode dispersar o foco do time operacional

---

## 4. ⚖️ Comparação Direta Entre as Três Propostas

### 4.1. Atingimento da Meta de 15%

| Critério | Gemini | ChatGPT | Claude |
|---|---|---|---|
| **Meta ($6.270/mês)** | ✅ `$6.880` (sobra `$610`) | ✅ `$6.500` (sobra `$425`) | ✅ `$6.540` (Cen.1) a `$8.550` (Cen.2) |
| **Margem de segurança** | 1,5% acima da meta | 1,0% acima da meta | **0,7% a 5,5%** acima |
| **Cálculo da base** | ✅ Correto (`$41.800`) | ⚠️ Incorreto (`$40.500`) | ✅ Correto (`$41.700` - diferença de arredondamento) |

**Vencedor:** Claude (Cenário 1 conservador) — meta atingida com folga de `$270` e margem para escalar para o Cenário 2 se necessário.

### 4.2. Preservação de SLA dos Sistemas Core (Chronos, Ledger, Reactor)

| Critério | Gemini | ChatGPT | Claude |
|---|---|---|---|
| **Chronos (API Gateway)** | Não afeta (foco em RI) | ⚠️ Menciona EKS consolidação (risco) | ⚠️ Cenário agressivo inclui EKS (risco) |
| **Ledger (RDS Multi-AZ)** | ✅ **Preserva Multi-AZ — RI apenas** | ⚠️ Sugere revisar necessidade de Multi-AZ | ✅ Cenário 1 preserva; Cenário 3 avaliaria downsize |
| **Reactor (filas)** | Não menciona | Não menciona | Não menciona diretamente |
| **Abordagem geral** | ✅ **Mais conservadora** | Moderada | Balanceada (por cenário) |

**Vencedor:** Gemini — a única proposta que **explicitamente afirma que não haverá alteração na arquitetura Multi-AZ do RDS** e que as economias vêm de compromissos financeiros, não de mudanças infraestruturais.

### 4.3. Priorização por Impacto

| Critério | Gemini | ChatGPT | Claude |
|---|---|---|---|
| **Ordenação por impacto** | ⚠️ Por fase, não por valor | ✅ Tabela ordenada por economia | ✅ Tabela ordenada |
| **% da conta por oportunidade** | ❌ Ausente | ✅ Presente | ✅ Presente |
| **Esforço por oportunidade** | ❌ Ausente | ✅ Baixo/Médio/Alto | ✅ Baixo/Médio/Alto |

**Vencedor:** ChatGPT — estrutura de tabela priorizada com % da conta e esforço é a mais alinhada ao enunciado da Q03.

### 4.4. Métricas Obrigatórias por Oportunidade

| Requisito da Q03 | Gemini | ChatGPT | Claude |
|---|---|---|---|
| **Percentual da conta total** | ❌ Não fornece | ✅ Fornece | ✅ Fornece |
| **Nível de esforço** | ❌ Não fornece | ✅ Fornece | ✅ Fornece |
| **Riscos detalhados** | ✅ Mitigações específicas | ⚠️ Genérico | ✅ Detalhado por iniciativa |
| **Pré-requisitos** | ✅ Por área (RDS, EC2, Logs) | ⚠️ Superficial | ✅ Detalhado por iniciativa |

**Vencedor:** Claude — é o único que atende **todos os quatro subcritérios** com profundidade.

### 4.5. Viabilidade, Risco e Rapidez

| Critério | Gemini | ChatGPT | Claude |
|---|---|---|---|
| **Viabilidade de implementação** | ✅ Alta (ações de faturamento) | ✅ Alta (foco em quick wins) | ✅ Alta (Cenário 1) |
| **Risco operacional** | ✅ **Menor risco** | ⚠️ Médio (EKS no pacote) | ⚠️ Médio (depende do cenário) |
| **Rapidez de captura** | Imediata (RIs mês 1) | Imediata (EC2 + CW Logs) | Imediata (EC2 RI + CW Logs) |
| **Impacto em sistemas core** | ✅ Mínimo | ⚠️ Médio (RDS) | ⚠️ Médio (EKS no Cen. 2) |
| **Aderência ao trimestre** | ✅ Sim (roadmap 3 meses) | ✅ Sim (sem cronograma) | ✅ Sim (roadmap 12 semanas) |

---

## 5. 🏆 Conclusão — Recomendação Final

### Qual proposta cumpre melhor a meta de redução de custos?

**Claude (Cenário 1 — Conservador).** Com `$6.540/mês` (15,7%) em 60 dias e risco baixo, a meta é atingida de forma **mais robusta** que as concorrentes. Além disso, o modelo de cenários permite à diretoria **escolher o nível de risco** sem precisar de uma segunda rodada de análise. O Cenário 2 agressivo (`$8.550` — 20,5%) serve como *target stretch* caso a primeira fase seja bem-sucedida.

### Qual proposta preserva melhor a estabilidade dos sistemas?

**Gemini.** É a única proposta que **deliberadamente evita qualquer alteração estrutural** nos sistemas core:
- RDS: apenas Reserved Instance (compromisso financeiro, não arquitetural)
- EC2: rightsizing condicionado a 14 dias de análise do Compute Optimizer
- Logs: arquivamento em S3 mantém acessibilidade
- S3: Intelligent-Tiering sem custo de recuperação

Para um CTO como **Doc Brown**, que precisa garantir que Chronos, Ledger e Reactor não sofram degradação, esta é a abordagem **mais defensiva e segura**.

### Qual proposta apresenta o melhor trade-off entre economia e segurança?

**Não há uma vencedora única — a recomendação é uma combinação:**

> 🏅 **Abordagem Híbrida Recomendada:**
> 
> **Pegue a estrutura de Claude** (3 cenários, roadmap semanal, matriz de risco SLA, pré-requisitos detalhados) como **formato de apresentação para Goldie e Doc**.
> 
> **Pegue a filosofia de Gemini** (preservação absoluta de Multi-AZ, sem tocar em sistemas core, foco em RIs financeiras) como **princípio de execução**.
> 
> **Pegue a priorização do ChatGPT** (tabela ordenada com % da conta e esforço) como **ferramenta de comunicação com a diretoria**.

**Proposta concreta para a reunião com Goldie e Doc:**

| Prioridade | Ação | Economia | Risco | Prazo |
|---|---|---|---|---|
| P0 | EC2 on-demand → RI 1-ano | `$2.870/mês` | Baixo | Semana 1-2 |
| P0 | CloudWatch Logs 90→30 dias | `$1.760/mês` | Baixo | Semana 1-2 |
| P1 | RDS PostgreSQL → RI (sem downsize) | `$820/mês`* | **Nulo** | Semana 3-4 |
| P1 | S3 Intelligent-Tiering | `~$500/mês`* | Baixo | Semana 3-4 |
| P2 | Lambda otimização + NAT consolidação | `$670/mês` | Baixo | Semana 5-8 |
| **Total** | | **`$6.620/mês (15,8%)`** | **Baixo** | **60 dias** |

*\*Estimativas — valores não explicitamente calculados pelos modelos para RDS RI e S3 Intelligent-Tiering*

---

## 6. ⚠️ Observações, Riscos e Pontos de Atenção

| Risco | Descrição | Impacto |
|---|---|---|
| **📊 Divergência de dados base** | ChatGPT calculou `$40.500` vs. `$41.800` real — sugere que o prompt T-A-G não especificou "some todos os valores do CSV e use o total exato" | Pode gerar desconfiança se não corrigido antes da apresentação |
| **🧠 EKS no radar** | Claude inclui consolidação EKS como Cenário 2; Lorraine (SRE) precisa ser consultada antes de qualquer movimento no Kubernetes | Médio-Alto |
| **📋 Pré-requisitos não validados** | Todos os modelos assumem dados de utilização médios sem considerar sazonalidade — Doc Brown precisa validar com métricas reais do Beacon | Alto |
| **🔐 Data Transfer Out sem contexto** | Nenhum modelo detalhou a origem do tráfego inter-região — essencial antes de implementar CloudFront | Médio |
| **🕒 Horizonte do trimestre** | Gemini propõe 3 meses; Claude propõe 60-90 dias; ChatGPT não define cronograma — a equipe SRE (Lorraine) precisa confirmar capacidade de execução | Médio |
| **📄 Lacuna de conformidade** | Redução de retenção de logs (CloudWatch) requer validação com Strickland (compliance) — mencionado apenas por Claude e Gemini | Médio |

---

**Preparado por:** Analista de Estratégia e Custos Cloud  
**Data:** 9 de junho de 2026  
**Destinatários:** Goldie Wilson (CEO) | Doc Brown (CTO)  
**CC:** Lorraine Baines (SRE) | Strickland (Compliance)