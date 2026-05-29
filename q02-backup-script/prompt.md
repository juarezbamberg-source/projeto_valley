# Q02 - Script de Backup do Ledger | Prompt T-A-G

## Framework Utilizado
**T-A-G (Task, Action, Goal)**

## Prompt Estruturado

### Task
Crie um script bash para backup automatizado do banco de dados PostgreSQL Ledger (ledger_prod) em um servidor Ubuntu 22.04 LTS.

### Action
O script deve:
1. Executar pg_dump do banco ledger_prod no host ledger-db.internal.hvt.io (porta 5432)
2. Usar o usuário backup_user com senha via variável de ambiente PGPASSWORD (AWS Secrets Manager)
3. Comprimir o dump com gzip
4. Fazer upload do arquivo para o bucket S3 hvt-ledger-backups (região us-east-1) via aws s3 cp
5. Manter apenas 30 dias de retenção no S3 (remover backups mais antigos automaticamente)
6. Registrar cada execução em /var/log/ledger-backup.log com timestamp, status e mensagens de erro
7. Retornar exit code 0 em sucesso e exit code 1 em falha
8. Ser executável via cron diariamente

### Goal
Garantir que backups diários do banco Ledger sejam executados automaticamente sem intervenção manual, com retenção de 30 dias, logs detalhados e tratamento robusto de erros. O script deve ser pronto para produção e seguro (sem expor credenciais em logs).

## Componentes do Framework

| Componente | Descrição | Aplicação |
|-----------|-----------|-----------|
| **Task** | O que fazer | Backup automatizado do PostgreSQL Ledger |
| **Action** | Como fazer / ações específicas | 8 ações detalhadas (pg_dump, gzip, S3, retenção, logging, exit codes, cron) |
| **Goal** | Resultado final esperado | Backups diários automatizados, pronto para produção |