 Q01
 Requisitos => R-T-F PARA 
 Aplicação: Lift (sistema de beta/testes)
Linguagem: Node.js (inferido pelo contexto de aplicação web moderna)
Porta padrão: 3000
Variáveis de ambiente críticas: NODE_ENV, LOG_LEVEL
Requisitos: Containerização otimizada, segurança (usuário não-root recomendado)

PROMPT
Role: Você é um engenheiro DevOps sênior especializado em containerização e otimização de imagens Docker.
Task: Crie um Dockerfile otimizado para a aplicação Lift (Node.js, porta 3000). O Dockerfile deve incluir:
- Suporte a variáveis de ambiente (NODE_ENV, LOG_LEVEL)
- Execução com usuário não-root por segurança
- Multi-stage build para reduzir tamanho da imagem
- Health check configurado
- Comentários explicativos em cada seção
Format: Retorne o Dockerfile completo em bloco de código, seguido de uma explicação de 5-7 linhas sobre as escolhas arquiteturais (por que multi-stage, por que usuário não-root, etc.).

