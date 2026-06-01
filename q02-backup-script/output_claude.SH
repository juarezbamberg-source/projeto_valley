#Instalar dependências (Necessário somente para primeira execução do script):
sudo apt-get update && sudo apt-get install -y postgresql-client awscli jq

#Criar usuário e diretório de logs:
sudo useradd -r -s /bin/bash ledger-backup
sudo mkdir -p /var/log && sudo touch /var/log/ledger-backup.log
sudo chown ledger-backup:ledger-backup /var/log/ledger-backup.log
sudo chmod 640 /var/log/ledger-backup.log

# Recuperar senha do Secrets Manager
export PGPASSWORD=$(aws secretsmanager get-secret-value \
  --secret-id ledger-backup-password \
  --region us-east-1 \
  --query SecretString \
  --output text)

#sudo crontab -e -u ledger-backup
# Adicionar linha:
0 2 * * * export PGPASSWORD=$(aws secretsmanager get-secret-value --secret-id ledger-backup-password --region us-east-1 --query SecretString --output text) && /usr/local/bin/ledger-backup.sh

#Tornar executável e instalar:
sudo cp ledger-backup.sh /usr/local/bin/
sudo chmod 750 /usr/local/bin/ledger-backup.sh

#Testar manualmente:
sudo -u ledger-backup bash -c 'export PGPASSWORD=$(aws secretsmanager get-secret-value --secret-id ledger-backup-password --region us-east-1 --query SecretString --output text) && /usr/local/bin/ledger-backup.sh'

# Monitorar logs:
sudo tail -f /var/log/ledger-backup.log


#INICIO DO SCRIPT DE BACKUP
#!/bin/bash
# Automated PostgreSQL Backup Script (ledger_prod -> S3)
# Set strict mode
set -o pipefail

# ---------- Configuration ----------
DB_HOST="ledger-db.internal.hvt.io"
DB_PORT="5432"
DB_NAME="ledger_prod"
DB_USER="backup_user"
S3_BUCKET="hvt-ledger-backups"
S3_REGION="us-east-1"
RETENTION_DAYS=30
LOG_FILE="/var/log/ledger-backup.log"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="/tmp/ledger_prod_${TIMESTAMP}.sql.gz"

# ---------- Logging ----------
log() {
    local level="$1"
    shift
    local message="$*"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [${level}] ${message}" >> "$LOG_FILE"
}

log_info() {
    log "INFO" "$@"
}

log_error() {
    log "ERROR" "$@"
}

# ---------- Notification (placeholder - extend with mail/Slack/Webhook) ----------
notify_failure() {
    local reason="$1"
    log_error "${reason}"
    # Example: send email (uncomment and configure if needed)
    # mail -s "Ledger Backup FAILED" admin@example.com <<< "${reason}"
    # Or use logger to syslog
    # logger -t ledger-backup "FAILED: ${reason}"
}

# ---------- Validation functions ----------
check_disk_space() {
    local required_mb=512  # Minimum free space required in MB
    local available_mb
    available_mb=$(df /tmp --output=avail 2>/dev/null | tail -1)
    if [[ -z "$available_mb" ]]; then
        notify_failure "Cannot determine disk space on /tmp"
        exit 1
    fi
    if (( available_mb < required_mb )); then
        notify_failure "Insufficient disk space on /tmp: ${available_mb}MB available, need ${required_mb}MB"
        exit 1
    fi
    log_info "Disk space check passed (${available_mb}MB available on /tmp)"
}

check_connectivity() {
    if ! command -v pg_isready &>/dev/null; then
        notify_failure "pg_isready not found. Install postgresql-client."
        exit 1
    fi
    if ! pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" &>/dev/null; then
        notify_failure "Cannot connect to PostgreSQL at ${DB_HOST}:${DB_PORT}"
        exit 1
    fi
    log_info "PostgreSQL connectivity check passed"
}

check_permissions() {
    # Ensure we can write to log file
    if ! touch "$LOG_FILE" &>/dev/null; then
        notify_failure "Cannot write to log file ${LOG_FILE}"
        exit 1
    fi
    # Ensure we can write to /tmp
    if ! touch "/tmp/.ledger_write_test" &>/dev/null; then
        notify_failure "Cannot write to /tmp"
        exit 1
    fi
    rm -f "/tmp/.ledger_write_test"
    log_info "Permissions check passed"
}

check_aws_cli() {
    if ! command -v aws &>/dev/null; then
        notify_failure "aws CLI not installed"
        exit 1
    fi
    log_info "AWS CLI available"
}

check_env_vars() {
    if [[ -z "${PGPASSWORD}" ]]; then
        notify_failure "PGPASSWORD environment variable not set"
        exit 1
    fi
    # Credentials must not be logged: we do not log the value
    log_info "PGPASSWORD is set (not printed for security)"
}

# ---------- Backup steps ----------
do_backup() {
    log_info "Starting backup of ${DB_NAME} from ${DB_HOST}:${DB_PORT}"
    # Export PGPASSWORD for pg_dump (set only for this process)
    export PGPASSWORD
    if ! pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" --no-owner --no-acl 2>/dev/null | gzip > "$BACKUP_FILE"; then
        notify_failure "pg_dump or compression failed"
        exit 1
    fi
    # Verify file is non-empty
    if [[ ! -s "$BACKUP_FILE" ]]; then
        notify_failure "Backup file is empty"
        exit 1
    fi
    log_info "Backup completed successfully: ${BACKUP_FILE} ($(du -h "$BACKUP_FILE" | cut -f1))"
}

do_upload() {
    log_info "Uploading backup to s3://${S3_BUCKET}/ledger_prod/"
    if ! aws s3 cp "$BACKUP_FILE" "s3://${S3_BUCKET}/ledger_prod/" --region "$S3_REGION" --only-show-errors; then
        notify_failure "Upload to S3 failed"
        exit 1
    fi
    log_info "Upload completed"
}

cleanup_old_backups() {
    log_info "Cleaning up backups older than ${RETENTION_DAYS} days"
    local cutoff_date
    cutoff_date=$(date -d "${RETENTION_DAYS} days ago" +%Y-%m-%d)
    # List all objects in bucket/prefix and delete those older than cutoff
    aws s3api list-objects \
        --bucket "$S3_BUCKET" \
        --prefix "ledger_prod/" \
        --query "Contents[?LastModified<='${cutoff_date}T00:00:00Z'].{Key: Key}" \
        --output json 2>/dev/null | \
        jq -r '.[].Key // empty' | \
        while read -r key; do
            log_info "Deleting old backup: ${key}"
            aws s3 rm "s3://${S3_BUCKET}/${key}" --quiet
        done
    log_info "Old backup cleanup complete"
}

# ---------- Main ----------
main() {
    # Redirect all errors to log
    exec 2>>"$LOG_FILE"

    log_info "=================== Ledger Backup started ==================="

    # Validate environment
    check_env_vars
    check_aws_cli
    check_permissions
    check_disk_space
    check_connectivity

    # Perform backup
    do_backup

    # Upload to S3
    do_upload

    # Retention (cleanup)
    cleanup_old_backups

    # Cleanup local file
    rm -f "$BACKUP_FILE"

    log_info "=================== Ledger Backup completed successfully ==================="
    exit 0
}

# Run main, catch unexpected errors
trap 'log_error "Unexpected error on line $LINENO"; exit 1' ERR

main "$@"
