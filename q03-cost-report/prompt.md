# Q03 - Relatório de Redução de Custos Cloud | Prompt C-A-R-E

## Framework Utilizado
**C-A-R-E (Context, Action, Result, Example)**

## Prompt Estruturado

### Context
Você é um analista de custos cloud sênior trabalhando para a Hill Valley Tech. A empresa precisa reduzir custos AWS em 30% nos próximos 6 meses. Os custos atuais são: EC2 $15k/mês, RDS $8k/mês, S3 $3k/mês, Lambda $2k/mês, outros $0.5k/mês (total: ~$28.5k/mês). O objetivo é chegar a ~$19.95k/mês.

### Action
Crie um relatório executivo de redução de custos cloud que:
1. Analise os custos atuais por serviço
2. Identifique 5-7 oportunidades de redução (reserved instances, spot instances, rightsizing, storage optimization, etc.)
3. Calcule o impacto financeiro de cada otimização (economia mensal e anual)
4. Apresente um roadmap de implementação com timeline (meses 1-6)
5. Mostre o ROI esperado e o custo total de implementação
6. Inclua riscos e mitigações para cada recomendação

### Result
Retorne um relatório estruturado com:
- Resumo executivo (1 parágrafo)
- Tabela de custos atuais por serviço
- Tabela de oportunidades com: Serviço, Oportunidade, Economia Mensal, Economia Anual, Esforço (Baixo/Médio/Alto), Timeline
- Gráfico de redução de custos (antes/depois)
- Roadmap de implementação (meses 1-6)
- Análise de riscos
- Conclusão com recomendação final

### Example
| Serviço | Oportunidade | Economia Mensal | Economia Anual | Esforço | Timeline |
|---------|-------------|-----------------|-----------------|---------|----------|
| EC2 | Reserved Instances (1 ano) | $3.000 | $36.000 | Baixo | Mês 1 |
| EC2 | Spot Instances para dev/test | $1.500 | $18.000 | Médio | Mês 2 |
| RDS | Reserved Instances (1 ano) | $1.600 | $19.200 | Baixo | Mês 1 |
| S3 | Intelligent-Tiering | $600 | $7.200 | Baixo | Mês 1 |
| Lambda | Otimização de memória | $300 | $3.600 | Médio | Mês 3 |

## Componentes do Framework

| Componente | Descrição | Aplicação |
|-----------|-----------|-----------|
| **Context** | Cenário e background | Analista de custos, meta de 30% redução, custos atuais |
| **Action** | Ações específicas a executar | 6 ações detalhadas (análise, identificação, cálculo, roadmap, ROI, riscos) |
| **Result** | Formato e estrutura esperada | Relatório com 7 seções (resumo, tabelas, gráfico, roadmap, riscos, conclusão) |
| **Example** | Exemplo concreto | Tabela com 5 oportunidades de redução |