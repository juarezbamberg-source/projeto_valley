Entendi. Você quer que eu mude de contexto: agora você está pedindo uma **análise de três arquivos de backup** (não mais Dockerfiles), e depois quer um **prompt de IA usando o framework R-T-F** para gerar um script bash de backup PostgreSQL.

Vou analisar os três arquivos anexados primeiro.---

## 1. Os 3 arquivos foram gerados sem erros?

**Não.**

O arquivo do **ChatGPT** contém um erro crítico na seção de limpeza de backups antigos: a lógica de cálculo de data está incompleta e não funcionaria em produção. A comparação de timestamps não é feita corretamente.

O arquivo do **Gemini** também tem uma falha: a remoção de backups antigos usa um fallback de script bash em vez de confiar em S3 Lifecycle Policy, o que é menos robusto.

---

## 2. Qual provedor gerou o melhor output?

**Claude**

---

## 3. Principais diferenças entre os 3 outputs

| Aspecto | Gemini | ChatGPT | Claude |
|---------|--------|---------|--------|
| **Estrutura geral** | Script simples, direto | Script com seções bem definidas | Script + guia de instalação |
| **Validações** | Mínimas (apenas senha) | Básicas (PGPASSWORD, pg_dump, aws) | Completas (disco, conectividade, permissões, AWS CLI, env vars) |
| **Tratamento de erros** | `set -euo pipefail` | Validações inline | Funções de validação dedicadas |
| **Logging** | Função `log()` simples | Função `log()` com timestamp | Função `log()` formatada + notificação placeholder |
| **Retenção de 30 dias** | Script bash (fallback) | Lógica incompleta/quebrada | Função dedicada com validação |
| **Permissões de arquivo** | Não aborda | Não aborda | Valida permissões antes de executar |
| **Conectividade PostgreSQL** | Não valida | Não valida | Valida conexão antes do backup |
| **Espaço em disco** | Não verifica | Não verifica | Verifica espaço disponível |
| **Documentação** | Comentários no script | Comentários em português | Guia de instalação + script comentado |
| **Instalação/Setup** | Não inclui | Não inclui | Inclui passos de instalação, usuário dedicado, cron |
| **Notificações** | Não inclui | Não inclui | Placeholder para alertas (email/Slack/Webhook) |
| **Clareza/Manutenibilidade** | Boa | Boa (mas com erro) | Excelente (estruturado, testável) |

**Pontos críticos:**
- **Claude**: Mais robusto e pronto para produção. Inclui validações preventivas, guia de instalação, e estrutura modular.
- **ChatGPT**: Erro na lógica de retenção inviabiliza a limpeza automática de backups antigos.
- **Gemini**: Funcional, mas menos completo. Recomenda S3 Lifecycle Policy como alternativa, o que é bom, mas não implementa.

---

## Agora: Prompt R-T-F para gerar o script bash

Aplicando o framework **R-T-F** (Role, Task, Format):

```
Role: Você é um especialista em automação de infraestrutura e backup de bancos de dados PostgreSQL em ambientes AWS.

Task: Escreva um script bash robusto e pronto para produção que:
1. Faça dump do banco ledger_prod via pg_dump com compactação gzip
2. Envie o arquivo para o bucket S3 hvt-ledger-backups na região us-east-1
3. Mantenha retenção automática de 30 dias (remova backups mais antigos)
4. Registre cada execução em /var/log/ledger-backup.log com timestamp
5. Saia com exit code apropriado em caso de falha
6. Valide pré-requisitos (disco, conectividade, permissões, AWS CLI)
7. Recupere a senha do AWS Secrets Manager via IAM role da instância

Contexto:
- Host: ledger-db.internal.hvt.io, Porta: 5432
- Banco: ledger_prod, Usuário: backup_user
- Diretório de trabalho: /var/backups/ledger (80 GB livres)
- Tamanho médio do dump: ~12 GB
- SO: Ubuntu 22.04 LTS
- Senha via variável PGPASSWORD (populada pelo AWS Secrets Manager)

Format: 
- Script bash executável com shebang #!/bin/bash
- Seções bem definidas com comentários claros
- Funções reutilizáveis para logging, validação e limpeza
- Exemplo de cron job para execução diária às 02:00
- Tratamento robusto de erros com set -euo pipefail
- Sem dependências externas além de: postgresql-client, awscli, gzip
```