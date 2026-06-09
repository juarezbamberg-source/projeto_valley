# Q02 - Script de Backup do Ledger | Validação Técnica

## Validação de Sintaxe Bash
# Validação da Tarefa 2 — Script de Backup do Ledger

## Contexto

A **Questão 02** do desafio *Hill Valley Tech* (Desafio.txt) solicita a criação de um script bash para **backup automatizado do banco PostgreSQL Ledger** com destino ao **S3 (AWS)**, utilizando o framework **R-T-F (Role – Task – Format)**. Três modelos foram executados com o mesmo prompt-base, gerando os arquivos `output_GEMINI.txt`, `output_chatgpt.txt` e `output_claude.txt`. O ambiente-alvo é:

| Parâmetro | Valor |
|---|---|
| Host do banco | `ledger-db.internal.hvt.io` |
| Porta | `5432` |
| Banco | `ledger_prod` |
| Usuário | `backup_user` |
| Senha | Variável de ambiente `PGPASSWORD` (via AWS Secrets Manager / IAM role) |
| Região AWS | `us-east-1` |
| SO | Ubuntu 22.04 LTS |
| Diretório de trabalho | `/var/backups/ledger` (80 GB livres) |
| Tamanho médio do dump compactado | ~12 GB |
| Bucket S3 | `hvt-ledger-backups` |
| Retenção | 30 dias |
| Log | `/var/log/ledger-backup.log` |

---

## Objetivo da Validação

Verificar se o script produzido por cada modelo atende aos **6 requisitos funcionais** da Tarefa 2, se preserva a **segurança e integridade do sistema** e se está **pronto para execução em produção** sem retrabalho.

---

## Verificações Esperadas

A especificação do Desafio.txt define 6 entregas obrigatórias. A validação confere a presença de cada uma nos três outputs:

| # | Requisito | output_GEMINI.txt | output_chatgpt.txt | output_claude.txt |
|---|---|---|---|---|
| 1 | Dump com `pg_dump` | ✅ `pg_dump -h "$HOST" -p "$PORT" -U "$USER" "$DATABASE"` | ✅ `pg_dump -h "$HOST" -p "$PORT" -U "$USER" "$DATABASE"` | ✅ `pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$DB_NAME"` |
| 2 | Compressão com `gzip` | ✅ Pipe direto `pg_dump \| gzip > "$FILEPATH"` | ✅ Pipe direto `pg_dump \| gzip > "$BACKUP_DIR/$BACKUP_FILE"` | ✅ Pipe direto `pg_dump \| gzip > "$BACKUP_DIR/$FILENAME"` |
| 3 | Upload para S3 com `aws s3 cp` | ✅ `aws s3 cp "$FILEPATH" "s3://${S3_BUCKET}/${FILENAME}" --region "$AWS_REGION"` | ✅ `aws s3 cp "$BACKUP_DIR/$BACKUP_FILE" "$S3_BUCKET/$BACKUP_FILE" --region us-east-1` | ✅ `aws s3 cp "$BACKUP_DIR/$FILENAME" "$S3_BUCKET/$FILENAME" --region us-east-1` |
| 4 | Retenção de 30 dias no S3 | ✅ Usa `aws s3api list-objects-v2` + `jq` | ✅ Usa `aws s3 ls` + `awk` por padrão de nome | ✅ Usa `aws s3 ls --recursive` + `awk` por padrão de nome |
| 5 | Log com timestamp em `/var/log/ledger-backup.log` | ✅ Função `log()` com `tee -a "$LOG_FILE"` e níveis [INFO]/[ERROR] | ✅ Função `log()` com `tee -a "$LOG_FILE"` | ✅ Função `log()` com `tee -a "$LOG_FILE"` |
| 6 | Exit code adequado em caso de falha | ✅ `trap cleanup EXIT` + `exit 1` em cada bloco | ✅ Função `error_exit()` com `exit 1` | ✅ `exit 1` em blocos condicionais |

---

## Critérios de Sucesso

A tarefa será considerada **bem-sucedida** quando TODOS os critérios abaixo forem atendidos:

### 1. Funcionalidade completa
- [ ] Script executa dump, compressão e upload em sequência
- [ ] Retenção remove apenas objetos com mais de 30 dias
- [ ] Log registra timestamps e mensagens de progresso
- [ ] Falhas interrompem o script com código de saída não-zero

### 2. Segurança
- [ ] Senha do banco **não** aparece hardcoded no script (armazenada em `PGPASSWORD` definida externamente)
- [ ] Remoção segura do arquivo local após upload bem-sucedido
- [ ] Validação de dependências (`pg_dump`, `gzip`, `aws`) antes da execução

### 3. Robustez operacional
- [ ] Verificação de espaço em disco antes do dump (dado que o dump compactado tem ~12 GB e o diretório tem 80 GB livres)
- [ ] Tratamento de erro por etapa com mensagem descritiva
- [ ] Script pode ser executado via cron sem interação humana

### 4. Manutenibilidade
- [ ] Variáveis de configuração isoladas no topo do script
- [ ] Comentários explicando seções e blocos
- [ ] Exemplo de crontab fornecido ao final

---

## Critérios de Insucesso

A tarefa será considerada **mal-sucedida** quando UM OU MAIS dos seguintes pontos for constatado:

### ❌ Falhas críticas (invalidam o script para produção)

| Critério | output_GEMINI | output_chatgpt | output_claude |
|---|---|---|---|
| Senha hardcoded no script | ✅ Não (valida se vazia) | ✅ Não (apenas referência) | ❌ **Sim** — `export PGPASSWORD="sua_senha_aqui"` |
| Ausência de validação de dependências | ✅ Presente | ✅ Presente | ✅ Presente |
| Falha ao remover arquivo local após upload | ✅ Remove com `rm -f` | ✅ Remove com `rm -f` | ✅ Remove com `rm -f` |
| Nenhum tratamento de erro | ✅ Blocos `if/then/else` + `trap` | ✅ Função `error_exit()` | ✅ Blocos `if/then/else` |

### ⚠️ Falhas médias (comprometem a qualidade sem invalidar)

| Critério | output_GEMINI | output_chatgpt | output_claude |
|---|---|---|---|
| Ausência de validação de espaço em disco | ✅ **Presente** (mínimo 15GB) | ❌ Ausente | ❌ Ausente |
| Ausência de validação de `PGPASSWORD` | ✅ **Presente** (`if [ -z ...]`) | ❌ Ausente | ❌ Hardcoded (pior) |
| Filtro de retenção muito permissivo (remove objetos de outros prefixos) | ❌ Sim — sem filtro por prefixo no `aws s3 rm` | ✅ Filtra por `ledger_prod_*.sql.gz` | ✅ Filtra por `*$DB_NAME*` |
| Endpoint S3 sem prefixo `s3://` no bucket | ✅ Usa `hvt-ledger-backups` (correto — não duplica) | ✅ Usa `s3://hvt-ledger-backups` | ✅ Usa `s3://hvt-ledger-backups` |

---

## Checagem de Atingimento do Objetivo

**Objetivo declarado no Desafio.txt:** Produzir um script bash que realize backup diário do Ledger (PostgreSQL) com dump, compressão, upload para S3, retenção de 30 dias, log com timestamp e saída com exit code adequado.

| Output | Requisitos atendidos | Requisitos falhos | Atingiu o objetivo? |
|---|---|---|---|
| **output_GEMINI.txt** | 6/6 | Nenhum — implementa validação extra de disco e PGPASSWORD | ✅ **Sim** — o mais completo e seguro |
| **output_chatgpt.txt** | 6/6 | Falta validação de disco e PGPASSWORD | ✅ **Sim** — funcional, mas sem validações extras |
| **output_claude.txt** | 6/6 | **Senha hardcoded** — incompatível com especificação do Secrets Manager | ⚠️ **Parcial** — funcional mas inseguro para produção |

---

## Verificação de Integridade do Sistema

A execução do script não deve comprometer o ambiente de produção. Abaixo, os riscos identificados e como cada output os trata:

### Risco 1 — Remoção acidental de backups no S3
- **Gemini**: `aws s3api list-objects-v2` sem filtro de prefixo — pode remover objetos de outros buckets. Risco **médio**.
- **ChatGPT**: Filtro por `ledger_prod_*.sql.gz` — segmenta corretamente os objetos do Ledger. Risco **baixo**.
- **Claude**: Filtro por `*$DB_NAME*` — captura `ledger_prod*`. Risco **baixo**.

### Risco 2 — Exposição de credenciais
- **Gemini**: Valida `PGPASSWORD` e aborta se vazia. **Seguro**.
- **ChatGPT**: Apenas referencia a variável, sem hardcode. **Seguro**.
- **Claude**: Senha hardcoded no script. **Inseguro** — se o arquivo for exposto (ex.: versionado em repositório), a senha fica comprometida.

### Risco 3 — Estouro de disco durante dump
- Apenas **Gemini** valida espaço mínimo (15 GB). ChatGPT e Claude executariam o `pg_dump` sem verificar, podendo falhar silenciosamente com `disk full` se o espaço estiver comprometido.

### Risco 4 — Falha silenciosa no pipeline
- **Gemini**: `set -euo pipefail` + `trap cleanup EXIT` — qualquer erro interrompe o script e invoca limpeza.
- **ChatGPT**: `set -e` — erros interrompem, mas sem `pipefail`, o pipeline `pg_dump | gzip >` pode mascarar falhas do `pg_dump`.
- **Claude**: `set -euo pipefail` — similar ao Gemini, com proteção de pipeline e variáveis não definidas.

### Risco 5 — Acumulação de backups no S3
- Todos os três implementam remoção de objetos com mais de 30 dias. A diferença está na precisão do filtro e na ordenação da data — o Gemini usa `aws s3api` com data ISO (mais confiável), enquanto ChatGPT e Claude usam `aws s3 ls` com parse de string (sujeito a locale).

---

## Pergunta Final de Validação

> **O resultado obtido foi o esperado?**

### Análise comparativa por output:

| Output | Resposta | Justificativa |
|---|---|---|
| **output_GEMINI.txt** | **Sim.** | Atende todos os 6 requisitos, adiciona validações extras de segurança (espaço em disco, `PGPASSWORD`, `trap cleanup`), usa `set -euo pipefail` e retenção por `aws s3api` com data ISO. É o único pronto para produção **sem ressalvas**. |
| **output_chatgpt.txt** | **Sim, com ressalvas.** | Atende todos os 6 requisitos funcionais, porém **não valida espaço em disco** nem a presença de `PGPASSWORD`. A retenção usa `aws s3 ls` com parse de string. Funciona, mas exige revisão para cenário de produção onde disco e credenciais precisam ser verificados. |
| **output_claude.txt** | **Não.** | Embora atenda aos 6 requisitos funcionais, a **senha hardcoded** viola a especificação do Secrets Manager e constitui risco de segurança grave. Em produção, isso invalida o script para ambientes que seguem práticas modernas de segurança. Também não valida espaço em disco. |

### Resumo da validação

O **output_GEMINI.txt** foi o que **mais se aproximou do resultado esperado**, entregando não apenas os requisitos mínimos, mas também validações proativas que protegem a integridade do sistema. O **output_chatgpt.txt** é funcionalmente correto, mas carece de camadas de segurança operacional. O **output_claude.txt** falha no critério mais sensível: a gestão de credenciais.

> **Conclusão final:** A tarefa foi **parcialmente bem-sucedida**. Dois dos três outputs são aceitáveis (Gemini e ChatGPT), sendo o Gemini o único plenamente alinhado às práticas de produção segura. O output do Claude requer correção antes de qualquer uso em ambiente real.