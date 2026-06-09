#!/bin/bash

# Script de Backup Profissional para PostgreSQL
# Destino: S3 (AWS)
# Ambiente: Ubuntu 22.04 LTS

set -e

# --- Configurações ---
HOST="ledger-db.internal.hvt.io"
PORT="5432"
DATABASE="ledger_prod"
USER="backup_user"
BACKUP_DIR="/var/backups/ledger"
S3_BUCKET="s3://hvt-ledger-backups"
RETENTION_DAYS=30
LOG_FILE="/var/log/ledger-backup.log"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_FILE="ledger_prod_${TIMESTAMP}.sql.gz"

# --- Funções de Suporte ---

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

error_exit() {
    log "ERRO: $1"
    exit 1
}

check_dependencies() {
    for cmd in pg_dump gzip aws; do
        if ! command -v $cmd &> /dev/null; then
            error_exit "Dependência '$cmd' não encontrada."
        fi
    done
}

# --- Execução Principal ---

log "Iniciando processo de backup para o banco $DATABASE"

# 1. Validar dependências
check_dependencies

# 2. Garantir diretório de backup
if [ ! -d "$BACKUP_DIR" ]; then
    mkdir -p "$BACKUP_DIR" || error_exit "Falha ao criar diretório $BACKUP_DIR"
fi

# 3. Executar Dump e Compressão
log "Executando pg_dump e compressão..."
export PGPASSWORD="$PGPASSWORD" # Certifique-se de que a variável esteja definida no ambiente
pg_dump -h "$HOST" -p "$PORT" -U "$USER" "$DATABASE" | gzip > "$BACKUP_DIR/$BACKUP_FILE" || error_exit "Falha no dump ou compressão"

# 4. Upload para S3
log "Enviando para S3..."
aws s3 cp "$BACKUP_DIR/$BACKUP_FILE" "$S3_BUCKET/$BACKUP_FILE" --region us-east-1 || error_exit "Falha no upload para S3"

# 5. Limpeza local (opcional, manter apenas o arquivo atual)
rm -f "$BACKUP_DIR/$BACKUP_FILE"

# 6. Limpeza de retenção no S3 (arquivos com mais de 30 dias)
log "Removendo backups antigos no S3 com mais de $RETENTION_DAYS dias..."
# Lista arquivos e remove os que excedem a data de retenção
aws s3 ls "$S3_BUCKET" | while read -r line; do
    create_date=$(echo "$line" | awk '{print $1" "$2}')
    create_ts=$(date -d "$create_date" +%s)
    limit_ts=$(date -d "$RETENTION_DAYS days ago" +%s)
    if [ "$create_ts" -lt "$limit_ts" ]; then
        file_name=$(echo "$line" | awk '{print $4}')
        if [[ "$file_name" == ledger_prod_*.sql.gz ]]; then
            aws s3 rm "$S3_BUCKET/$file_name"
            log "Removido: $file_name"
        fi
    fi
done

log "Backup concluído com sucesso."
exit 0

# --- Exemplo de Cron (Adicionar em /etc/crontab ou crontab -e) ---
# 0 2 * * * root PGPASSWORD='sua_senha_aqui' /usr/local/bin/backup_ledger.sh