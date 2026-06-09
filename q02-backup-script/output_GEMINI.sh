#!/bin/bash

# Script de Backup PostgreSQL para S3
# Autor: Automação de Infraestrutura
# Descrição: Realiza dump, compressão, upload para S3 e limpeza de retenção.

set -euo pipefail

# --- Configurações ---
HOST="ledger-db.internal.hvt.io"
PORT="5432"
DATABASE="ledger_prod"
USER="backup_user"
BACKUP_DIR="/var/backups/ledger"
S3_BUCKET="hvt-ledger-backups"
AWS_REGION="us-east-1"
RETENTION_DAYS=30
LOG_FILE="/var/log/ledger-backup.log"

# --- Funções de Log ---
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$1] $2" | tee -a "$LOG_FILE"
}

# --- Tratamento de Erros e Limpeza ---
cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        log "ERROR" "Script falhou com código $exit_code. Limpando arquivos temporários..."
    fi
    exit $exit_code
}
trap cleanup EXIT

# --- Validações ---
log "INFO" "Iniciando validações..."
for cmd in pg_dump gzip aws; do
    if ! command -v $cmd &> /dev/null; then
        log "ERROR" "Comando $cmd não encontrado."; exit 1
    fi
done

if [ -z "${PGPASSWORD:-}" ]; then
    log "ERROR" "Variável PGPASSWORD não definida."; exit 1
fi

# Validar espaço em disco (mínimo 15GB para dump de 12GB)
AVAILABLE_SPACE=$(df -BG "$BACKUP_DIR" | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "$AVAILABLE_SPACE" -lt 15 ]; then
    log "ERROR" "Espaço em disco insuficiente em $BACKUP_DIR. Disponível: ${AVAILABLE_SPACE}GB"; exit 1
fi

# --- Execução do Backup ---
mkdir -p "$BACKUP_DIR"
TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
FILENAME="${DATABASE}_${TIMESTAMP}.sql.gz"
FILEPATH="${BACKUP_DIR}/${FILENAME}"

log "INFO" "Iniciando dump do banco $DATABASE..."
if pg_dump -h "$HOST" -p "$PORT" -U "$USER" "$DATABASE" | gzip > "$FILEPATH"; then
    log "INFO" "Dump concluído com sucesso: $FILENAME"
else
    log "ERROR" "Falha no pg_dump."; exit 1
fi

# --- Upload para S3 ---
log "INFO" "Iniciando upload para s3://$S3_BUCKET/..."
if aws s3 cp "$FILEPATH" "s3://${S3_BUCKET}/${FILENAME}" --region "$AWS_REGION"; then
    log "INFO" "Upload concluído. Removendo arquivo local."
    rm -f "$FILEPATH"
else
    log "ERROR" "Falha no upload para S3."; exit 1
fi

# --- Retenção no S3 ---
log "INFO" "Iniciando limpeza de backups antigos no S3..."
THRESHOLD_DATE=$(date -d "$RETENTION_DAYS days ago" +%s)

aws s3api list-objects-v2 --bucket "$S3_BUCKET" --query "Contents[].{Key: Key, LastModified: LastModified}" --output json | jq -c '.[]' | while read -r object; do
    KEY=$(echo "$object" | jq -r '.Key')
    LAST_MODIFIED=$(echo "$object" | jq -r '.LastModified')
    MOD_DATE=$(date -d "$LAST_MODIFIED" +%s)

    if [ "$MOD_DATE" -lt "$THRESHOLD_DATE" ]; then
        log "INFO" "Removendo backup antigo do S3: $KEY"
        aws s3 rm "s3://${S3_BUCKET}/${KEY}"
    fi
done

log "INFO" "Backup diário finalizado com sucesso."

# --- Configuração do Crontab ---
# Adicione a linha abaixo ao seu crontab (crontab -e):
# 0 2 * * * PGPASSWORD='sua_senha_aqui' /usr/local/bin/backup_ledger.sh >> /var/log/ledger-backup.log 2>&1