# Prompt: Geração de Script Bash para Backup Diário do PostgreSQL

## Role (Papel)
Você é um Engenheiro SRE Sênior especializado em automação de banco de dados e AWS, trabalhando nos padrões da Hill Valley Tech. Sua responsabilidade é criar scripts de backup robustos, profissionais e prontos para produção.

## Task (Tarefa)
Gere um script Bash profissional que execute o backup diário do banco de dados Ledger (PostgreSQL) com as seguintes características:

### Ambiente e Configuração
- Sistema operacional: Ubuntu 22.04 LTS
- Diretório de trabalho: `/var/backups/ledger`
- Espaço livre disponível: 80 GB
- Tamanho aproximado do dump: 12 GB

### Conexão com o Banco de Dados
- Host: `ledger-db.internal.hvt.io`
- Porta: `5432`
- Banco de dados: `ledger_prod`
- Usuário: `backup_user`
- Senha: obtida via variável de ambiente `PGPASSWORD`

### Etapas de Execução
1. Executar `pg_dump` para extrair o banco de dados
2. Compactar o dump com `gzip`
3. Enviar o arquivo compactado para o bucket S3 `hvt-ledger-backups` na região `us-east-1` usando `aws s3 cp`
4. Remover arquivos com mais de 30 dias de idade do bucket S3

### Observabilidade e Confiabilidade
- Registrar todos os eventos em `/var/log/ledger-backup.log` com timestamps
- O script deve encerrar com código de erro se qualquer etapa falhar (dump, compressão ou upload)
- Implementar tratamento de erros robusto usando `set -e` e/ou verificações explícitas de status de saída
- Incluir mensagens de log descritivas para cada etapa (início, sucesso, erro)

## Format (Formato)
Entregue um script Bash com as seguintes características:

### Estrutura
- **Seção de Configuração**: variáveis de ambiente e parâmetros no início do script (HOST, PORT, DATABASE, USER, BACKUP_DIR, S3_BUCKET, RETENTION_DAYS, LOG_FILE)
- **Funções de Suporte**: funções para logging, validação de pré-requisitos e limpeza
- **Corpo Principal**: execução sequencial das etapas de backup
- **Tratamento de Erros**: verificações explícitas após cada comando crítico
- **Comentários Detalhados**: explicação de cada seção e comando importante

### Requisitos Técnicos
- Usar `#!/bin/bash` como shebang
- Implementar `set -e` para falhar rápido em caso de erro
- Validar a existência de ferramentas necessárias (`pg_dump`, `gzip`, `aws`)
- Validar a existência do diretório de backup e criar se necessário
- Usar timestamps no nome do arquivo de backup (formato: `ledger_prod_YYYY-MM-DD_HH-MM-SS.sql.gz`)
- Registrar logs com data/hora em cada operação
- Implementar limpeza de arquivos antigos no S3 com base em data de modificação
- Retornar código de saída apropriado (0 para sucesso, 1 para falha)

### Sugestão de Agendamento
Ao final do script, forneça um exemplo de entrada cron para execução automática diária às 02:00 da manhã:
0 2 * * * /caminho/para/script.sh >> /var/log/ledger-backup.log 2>&1