#!/usr/bin/env bash
set -euo pipefail

# 
# Script: pg_backup_ledger_prod.sh
# Descrição: Backup automatizado do PostgreSQL para S3.
# Requisitos: aws-cli, pg_dump, gzip.
# Uso: export PGPASSWORD="senha"; ./pg_backup_ledger_prod.sh
# 

# --- Configurações ---
DB_HOST="ledger-db.internal.hvt.io"
DB_PORT="5432"
DB_NAME="ledger_prod"
DB_USER="backup_user"
S3_BUCKET="hvt-ledger-backups"
S3_REGION="us-east-1"
S3_PREFIX="backups/ledger_prod"   # estrutura YYYY/MM/DD/ arquivo
RETENTION_DAYS=30
LOG_FILE="/var/log/ledger-backup.log"
TIMEOUT=300  # segundos para pg_dump (5 min)

# --- Função de logging ---
log() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    echo "${timestamp} [${level}] ${message}" >> "${LOG_FILE}"
}

# --- Validação inicial ---
if [[ -z "${PGPASSWORD+x}" ]]; then
    log "ERROR" "Variável de ambiente PGPASSWORD não definida."
    exit 1
fi

if ! command -v pg_dump &> /dev/null; then
    log "ERROR" "pg_dump não encontrado. Instale postgresql-client."
    exit 1
fi

if ! command -v aws &> /dev/null; then
    log "ERROR" "aws-cli não encontrado. Instale e configure."
    exit 1
fi

# --- Criação de diretório temporário seguro ---
TMP_DIR="$(mktemp -d /tmp/ledger_backup.XXXXXX)"
trap 'rm -rf "${TMP_DIR}"; log "INFO" "Diretório temporário removido: ${TMP_DIR}";' EXIT

# --- Geração do nome do arquivo com data/hora ---
TIMESTAMP="$(date '+%Y%m%d-%H%M%S')"
YEAR="$(date '+%Y')"
MONTH="$(date '+%m')"
DAY="$(date '+%d')"
FILENAME="ledger_prod-${TIMESTAMP}.sql.gz"
LOCAL_PATH="${TMP_DIR}/${FILENAME}"
S3_PATH="s3://${S3_BUCKET}/${S3_PREFIX}/${YEAR}/${MONTH}/${DAY}/${FILENAME}"

log "INFO" "Iniciando backup do banco ${DB_NAME} em ${DB_HOST}:${DB_PORT}."

# --- Execução do 


#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Script: pg_backup_ledger_prod.sh
# Descrição: Backup automatizado do PostgreSQL para S3.
# Requisitos: aws-cli, pg_dump, gzip.
# Uso: export PGPASSWORD="senha"; ./pg_backup_ledger_prod.sh
# ============================================================

# --- Configurações ---
DB_HOST="ledger-db.internal.hvt.io"
DB_PORT="5432"
DB_NAME="ledger_prod"
DB_USER="backup_user"
S3_BUCKET="hvt-ledger-backups"
S3_REGION="us-east-1"
S3_PREFIX="backups/ledger_prod"   # estrutura YYYY/MM/DD/ arquivo
RETENTION_DAYS=30
LOG_FILE="/var/log/ledger-backup.log"
TIMEOUT=300  # segundos para pg_dump (5 min)

# --- Função de logging ---
log() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    echo "${timestamp} [${level}] ${message}" >> "${LOG_FILE}"
}

# --- Validação inicial ---
if [[ -z "${PGPASSWORD+x}" ]]; then
    log "ERROR" "Variável de ambiente PGPASSWORD não definida."
    exit 1
fi

if ! command -v pg_dump &> /dev/null; then
    log "ERROR" "pg_dump não encontrado. Instale postgresql-client."
    exit 1
fi

if ! command -v aws &> /dev/null; then
    log "ERROR" "aws-cli não encontrado. Instale e configure."
    exit 1
fi

# --- Criação de diretório temporário seguro ---
TMP_DIR="$(mktemp -d /tmp/ledger_backup.XXXXXX)"
trap 'rm -rf "${TMP_DIR}"; log "INFO" "Diretório temporário removido: ${TMP_DIR}";' EXIT

# --- Geração do nome do arquivo com data/hora ---
TIMESTAMP="$(date '+%Y%m%d-%H%M%S')"
YEAR="$(date '+%Y')"
MONTH="$(date '+%m')"
DAY="$(date '+%d')"
FILENAME="ledger_prod-${TIMESTAMP}.sql.gz"
LOCAL_PATH="${TMP_DIR}/${FILENAME}"
S3_PATH="s3://${S3_BUCKET}/${S3_PREFIX}/${YEAR}/${MONTH}/${DAY}/${FILENAME}"

log "INFO" "Iniciando backup do banco ${DB_NAME} em ${DB_HOST}:${DB_PORT}."

# --- Execução do pg_dump com compactação em pipeline ---
# Usar PGPASSWORD via ambiente (não exposta em logs)
PGPASSWORD="${PGPASSWORD}" pg_dump \
    -h "${DB_HOST}" \
    -p "${DB_PORT}" \
    -U "${DB_USER}" \
    -d "${DB_NAME}" \
    --no-owner \
    --no-acl \
    --compress=0 \
    --inserts \
    2>> "${LOG_FILE}" \
| gzip -c > "${LOCAL_PATH}"

PG_EXIT_CODE="${PIPESTATUS[0]}"
if [[ "${PG_EXIT_CODE}" -ne 0 ]]; then
    log "ERROR" "pg_dump falhou com código ${PG_EXIT_CODE}."
    exit 1
fi

# Verificar se o arquivo local foi gerado e é maior que zero
if [[ ! -s "${LOCAL_PATH}" ]]; then
    log "ERROR" "Arquivo de dump vazio ou não criado."
    exit 1
fi

log "INFO" "Dump criado com sucesso: ${LOCAL_PATH} (tamanho: $(du -h "${LOCAL_PATH}" | cut -f1))"

# --- Upload para S3 ---
log "INFO" "Fazendo upload para ${S3_PATH}"
aws s3 cp "${LOCAL_PATH}" "${S3_PATH}" \
    --region "${S3_REGION}" \
    --no-progress \
    2>> "${LOG_FILE}"

AWS_EXIT_CODE="${?}"
if [[ "${AWS_EXIT_CODE}" -ne 0 ]]; then
    log "ERROR" "Upload para S3 falhou com código ${AWS_EXIT_CODE}."
    exit 1
fi

log "INFO" "Upload concluído com sucesso: ${S3_PATH}"

# --- Limpeza de backups antigos no S3 (retenção de 30 dias) ---
log "INFO" "Iniciando limpeza de backups com mais de ${RETENTION_DAYS} dias no S3."

CUTOFF_DATE="$(date -d "${RETENTION_DAYS} days ago" '+%Y-%m-%dT%H:%M:%SZ')"

# Lista todos os objetos sob o prefixo, filtra por data de modificação anterior ao cutoff
aws s3api list-objects-v2 \
    --bucket "${S3_BUCKET}" \
    --prefix "${S3_PREFIX}/" \
    --query "Contents[?LastModified<='${CUTOFF_DATE}'].{Key:Key}" \
    --output json \
    2>> "${LOG_FILE}" \
| jq -r '.[].Key' > "${TMP_DIR}/old_backups.txt" 2>> "${LOG_FILE}" || true

# Se houver arquivos antigos, exclui
if [[ -s "${TMP_DIR}/old_backups.txt" ]]; then
    TOTAL_OLD="$(wc -l < "${TMP_DIR}/old_backups.txt")"
    log "INFO" "Removendo ${TOTAL_OLD} backup(s) antigo(s)."
    while IFS= read -r obj; do
        aws s3 rm "s3://${S3_BUCKET}/${obj}" \
            --region "${S3_REGION}" \
            2>> "${LOG_FILE}" && \
            log "INFO" "Removido: ${obj}" || \
            log "WARN" "Falha ao remover: ${obj}"
    done < "${TMP_DIR}/old_backups.txt"
else
    log "INFO" "Nenhum backup com mais de ${RETENTION_DAYS} dias encontrado."
fi

log "INFO" "Backup e limpeza concluídos com sucesso."
exit 0
# ============================================================
# Instrução para cron (execução diária às 02:00):
# 0 2 * * * /usr/local/bin/pg_backup_ledger_prod.sh
# ============================================================