#!/bin/bash

# Script de Backup PostgreSQL para S3
# Autor: DevOps Team
# Descricao: Backup diario do banco ledger_prod com rotatividade no S3

set -euo pipefail

# --- Configuracoes ---
DB_HOST="ledger-db.internal.hvt.io"
DB_PORT="5432"
DB_NAME="ledger_prod"
DB_USER="backup_user"
export PGPASSWORD="sua_senha_aqui"

BACKUP_DIR="/var/backups/ledger"
LOG_FILE="/var/log/ledger-backup.log"
S3_BUCKET="s3://hvt-ledger-backups"
RETENTION_DAYS=30
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
FILENAME="${DB_NAME}_${TIMESTAMP}.sql.gz"

# --- Funcoes de Suporte ---
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

check_dependencies() {
    for cmd in pg_dump gzip aws; do
        if ! command -v $cmd &> /dev/null; then
            log "ERRO: Comando $cmd nao encontrado."
            exit 1
        fi
    done
}

# --- Execucao ---
check_dependencies

if [ ! -d "$BACKUP_DIR" ]; then
    mkdir -p "$BACKUP_DIR"
fi

log "Iniciando backup do banco $DB_NAME..."

# 1. pg_dump e compressao
if pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$DB_NAME" | gzip > "$BACKUP_DIR/$FILENAME"; then
    log "Backup local criado com sucesso: $FILENAME"
else
    log "ERRO: Falha no pg_dump."
    exit 1
fi

# 2. Upload para S3
log "Enviando para S3..."
if aws s3 cp "$BACKUP_DIR/$FILENAME" "$S3_BUCKET/$FILENAME" --region us-east-1; then
    log "Upload concluido com sucesso."
    rm -f "$BACKUP_DIR/$FILENAME"
else
    log "ERRO: Falha no upload para S3."
    exit 1
fi

# 3. Limpeza de arquivos antigos no S3
log "Removendo backups com mais de $RETENTION_DAYS dias no S3..."
# Lista e deleta objetos antigos
aws s3 ls "$S3_BUCKET" --recursive | while read -r line; do
    create_date=$(echo "$line" | awk '{print $1" "$2}')
    create_date=$(date -d "$create_date" +%s)
    older_than=$(date -d "$RETENTION_DAYS days ago" +%s)
    if [ "$create_date" -lt "$older_than" ]; then
        file_name=$(echo "$line" | awk '{print $4}')
        if [[ "$file_name" == *"$DB_NAME"* ]]; then
            aws s3 rm "$S3_BUCKET/$file_name"
            log "Removido: $file_name"
        fi
    fi
done

log "Processo de backup finalizado com sucesso."
exit 0

# --- Exemplo de Cron (crontab -e) ---
# 0 2 * * * /usr/local/bin/backup_ledger.sh >> /var/log/ledger-backup.log 2>&1