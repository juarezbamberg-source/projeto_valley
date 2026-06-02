Hill Valley Tech
PROJETO VALLEY - DESAFIO DE PROMPT ENGINEERING
Documentação Técnica, Metodologia de Prompting e Análise de Viés em Modelos de Linguagem
02 de junho de 2026

1. Visão Geral do Projeto
Este repositório contém a resolução do Desafio de Prompt Engineering aplicado ao ecossistema tecnológico da Hill Valley Tech. O projeto consiste na aplicação prática de técnicas avançadas de engenharia de prompts para resolver problemas críticos em cinco sistemas fundamentais: Chronos (API de transações), Ledger (Banco de dados), Reactor (Mensageria), Beacon (Observabilidade) e Strickland (Segurança/Compliance).
O objetivo central é demonstrar como a estruturação semântica de instruções pode otimizar tarefas de SRE, DevOps e Desenvolvimento, utilizando a colaboração simulada de personagens como Doc Brown, Lorraine e Strickland para contextualizar cenários reais de infraestrutura e automação.
2. Premissas do Projeto
O desenvolvimento deste projeto foi regido pelas seguintes premissas técnicas e metodológicas:
●	Resolução de 8 Questões Técnicas: Cada desafio (Q01 a Q08) aborda uma dor específica do cotidiano de operações, desde a criação de Dockerfiles até a análise de postmortems.
●	Aplicação de Frameworks Estruturados: Uso obrigatório de frameworks reconhecidos pelo mercado: R-T-F, T-A-G, B-A-B, C-A-R-E e R-I-S-E.
●	Multi-Provedores de IA: Testagem e comparação de outputs gerados por ChatGPT (OpenAI), Claude (Anthropic), Gemini (Google) e DeepSeek.
●	Análise Comparativa: Avaliação crítica de cada resposta para identificar alucinações, precisão técnica e aderência aos requisitos.
●	Versionamento Intencional: Estrutura de pastas desenhada para facilitar a rastreabilidade do aprendizado e a evolução dos prompts.
3. Fluxo e Metodologia
Para cada questão, foi seguido um fluxo rigoroso de documentação para garantir a reprodutibilidade dos resultados:
1.	Prompt: O texto exato da instrução enviada aos modelos.
2.	Modelo: Identificação do LLM utilizado e a justificativa técnica para sua escolha.
3.	Output: A resposta bruta gerada pela inteligência artificial.
4.	Justificativa: Análise técnica de como os componentes do framework escolhido foram aplicados e por que aquela estrutura foi eficaz.
4. Critérios de Avaliação das Saídas Geradas por IA
A qualidade dos artefatos gerados foi medida com base nos seguintes pilares:
●	Completude: Se o modelo atendeu a todos os requisitos solicitados sem omitir seções críticas.
●	Clareza e Estrutura: Organização lógica da informação e facilidade de leitura.
●	Aderência ao Framework: Verificação se o modelo respeitou as restrições de papel, tarefa, contexto ou passos definidos.
●	Qualidade Técnica: Precisão de códigos (Terraform, SQL, Shell, YAML) e comandos sugeridos.
●	Executabilidade: Capacidade do output ser utilizado imediatamente em um ambiente de produção (ready-to-use).
5. Observações sobre o uso de diferentes modelos como avaliadores
Um dos achados mais relevantes deste projeto foi a identificação do viés de auto-preferência (self-preference bias) nos modelos de linguagem durante a fase de julgamento.
"Estava usando Gemini, GPT e Claude para gerar os artefatos e usando o Claude para fazer a análise comparativa e a justificativa de qual saída era melhor... adivinha? O resultado sempre apontava a resposta do próprio Claude como a melhor 😅 Fiquei intrigado com isso e resolvi testar: no exercício 6 fiz a mesma análise usando o DeepSeek como avaliador... e dessa vez o resultado apontou a saída do GPT como a melhor! 🎯 Conclusão: as IAs também são bairristas! 😂 Cada modelo tende a favorecer o estilo de resposta que ele mesmo produziria. É um ponto importante pra quem trabalha com AIOps — na hora de usar IA para avaliação de outros artefatos de IA, o modelo avaliador não é neutro. Vale considerar isso ao definir pipelines de revisão automatizada. Como estou um pouco atrasado na timeline, não vou aprofundar agora, mas fica o registro da experiência pra galera! 🚀"
Esta experiência ressalta que, em pipelines de AIOps ou LLM-as-a-Judge, a neutralidade é um desafio técnico. A escolha do modelo avaliador pode distorcer a percepção de qualidade, favorecendo padrões sintáticos e semânticos familiares ao próprio avaliador.
6. Estrutura do Repositório
O repositório está organizado de forma modular para refletir cada etapa do desafio:
●	q01-docker-optimization/: Otimização de imagens para a Chronos API.
●	q02-backup-automation/: Scripts de automação para o Ledger.
●	q03-cost-analysis/: Relatórios de custos de infraestrutura.
●	q04-sql-optimization/: Queries complexas para análise de transações.
●	q05-modernize-deployment/: Refatoração de manifests Kubernetes.
●	q06-terraform-s3/: Módulos de infraestrutura como código.
●	q07-runbook-memory/: Procedimentos operacionais para incidentes.
●	q08-postmortem-incident/: Análise de causa raiz e lições aprendidas.
7. Questões e Frameworks
ID	Questão Técnica	Framework	Modelo Avaliador
Q01	Dockerfile Chronos API	R-T-F	Claude 3.5 Sonnet
Q02	Script de Backup Ledger	R-T-F	Claude 3.5 Sonnet
Q03	Relatório de Custos Cloud	T-A-G	Claude 3.5 Sonnet
Q04	Query SQL Transações	T-A-G	Claude 3.5 Sonnet
Q05	Modernização de Deployment	B-A-B	Claude 3.5 Sonnet
Q06	Módulo Terraform S3	C-A-R-E	Claude 3.5 Sonnet
Q07	Runbook de Memória Alta	R-I-S-E	DeepSeek-V3
Q08	Postmortem de Incidente	T-A-G	DeepSeek-V3
8. Conclusão e Lições Aprendidas
A conclusão deste projeto reforça que a Engenharia de Prompts não é apenas sobre "escrever instruções", mas sobre projetar contextos que reduzam a entropia das respostas da IA. O uso de frameworks como T-A-G e R-I-S-E provou ser essencial para obter respostas técnicas que não necessitem de refatoração humana extensiva.
Além disso, a descoberta sobre o bairrismo das IAs serve como um alerta para arquiteturas de software que utilizam IA para validar IA. Para garantir a qualidade em escala, é recomendável o uso de modelos distintos para geração e avaliação, ou a implementação de critérios de validação programáticos (testes unitários, linters) que complementem o julgamento do LLM.
