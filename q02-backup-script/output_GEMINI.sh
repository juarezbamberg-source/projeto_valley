#!/usr/bin/env bash
#
# Script: ledger_backup.sh
# Description: Automated backup of PostgreSQL database 'ledger_prod' to S3.
#              Designed for Ubuntu 22.04 LTS.
# Usage: sudo bash ledger_backup.sh
#

# ---------------------------------------------------------------------------
# Strict error handling
# ---------------------------------------------------------------------------
set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration variables
# ---------------------------------------------------------------------------
HOST="ledger-db.internal.hvt.io"
PORT="5432"
USER="backup_user"
DATABASE="ledger_prod"
S3_BUCKET="hvt-ledger-backups"
S3_REGION="us-east-1"
LOG_FILE="/var/log/ledger-backup.log"
SECRET_ID="ledger/db/backup_user"      # AWS Secrets Manager secret ID

# ---------------------------------------------------------------------------
# Logging function: writes timestamped messages to LOG_FILE and stdout
# ---------------------------------------------------------------------------
log() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "${timestamp} [${level}] ${message}" | tee -a "$LOG_FILE"
}

# ---------------------------------------------------------------------------
# Cleanup function: remove temporary dump file
# ---------------------------------------------------------------------------
cleanup() {
    if [[ -n "$DUMP_FILE" && -f "$DUMP_FILE" ]]; then
        rm -f "$DUMP_FILE"
        log "INFO" "Temporary dump file ${DUMP_FILE} removed."
    fi
}
trap cleanup EXIT

# ---------------------------------------------------------------------------
# Main script
# ---------------------------------------------------------------------------

# Log start
log "INFO" "Starting PostgreSQL backup script for database ${DATABASE}."

# 1. Retrieve database password from AWS Secrets Manager
log "INFO" "Retrieving password from Secrets Manager (secret-id: ${SECRET_ID})."
SECRET_VALUE=$(aws secretsmanager get-secret-value \
    --secret-id "$SECRET_ID" \
    --region "$S3_REGION" \
    --query SecretString \
    --output text 2>/dev/null) || {
    log "ERROR" "Failed to retrieve secret ${SECRET_ID} from AWS Secrets Manager."
    exit 1
}

PGPASSWORD=$(echo "$SECRET_VALUE" | jq -r '.password // empty' 2>/dev/null) || {
    log "ERROR" "Failed to extract password from secret JSON using jq."
    exit 1
}

if [[ -z "$PGPASSWORD" ]]; then
    log "ERROR" "Password extracted from secret is empty."
    exit 1
fi
export PGPASSWORD

# 2. Define dump file name and path
DUMP_FILE="/tmp/${DATABASE}_$(date '+%Y%m%d_%H%M%S').sql.gz"

# 3. Run pg_dump piped through gzip to create compressed dump
log "INFO" "Running pg_dump for database ${DATABASE}."
pg_dump -h "$HOST" -p "$PORT" -U "$USER" -d "$DATABASE" \
    --no-password --no-owner --no-acl \
    2>>"$LOG_FILE" | gzip > "$DUMP_FILE" 2>>"$LOG_FILE" || {
    log "ERROR" "pg_dump/gzip failed for database ${DATABASE}."
    exit 1
}
log "INFO" "Dump file created: ${DUMP_FILE}"

# 4. Upload dump file to S3
log "INFO" "Uploading dump file to S3 bucket ${S3_BUCKET}."
aws s3 cp "$DUMP_FILE" "s3://${S3_BUCKET}/" --region "$S3_REGION" 2>>"$LOG_FILE" || {
    log "ERROR" "Failed to upload ${DUMP_FILE} to S3 bucket ${S3_BUCKET}."
    exit 1
}
log "INFO" "Upload completed successfully."

# 5. Remove old backups from S3 (older than 30 days)
# NOTE: The recommended production practice is to use an S3 Lifecycle Policy
#       to automatically expire objects older than 30 days.
#       The following code provides a script-level fallback for immediate
#       cleanup without relying solely on lifecycle rules.
log "INFO" "Removing S3 backups older than 30 days."
THIRTY_DAYS_AGO=$(date -d "30 days ago" +%Y-%m-%d)
# List objects in the bucket and delete those with LastModified before THIRTY_DAYS_AGO
aws s3api list-objects-v2 \
    --bucket "$S3_BUCKET" \
    --query "Contents[?LastModified < '${THIRTY_DAYS_AGO}'].Key" \
    --output text \
    --region "$S3_REGION" 2>>"$LOG_FILE" | while read -r key; do
        if [[ -n "$key" ]]; then
            aws s3 rm "s3://${S3_BUCKET}/${key}" --region "$S3_REGION" 2>>"$LOG_FILE" && \
                log "INFO" "Deleted old backup: ${key}"
        fi
    done

# 6. Clean the password from environment (trap already removes the dump file)
unset PGPASSWORD
log "INFO" "Backup completed successfully. Exiting with code 0."
exit 0

# ---------------------------------------------------------------------------
# Crontab configuration:
# To run this script daily at 02:00 AM, add the following line to crontab:
# 0 2 * * * /path/to/ledger_backup.sh
# Ensure the script is executable (chmod +x /path/to/ledger_backup.sh)
# and run by a user with necessary AWS CLI permissions and sudo access if needed.
# Example installation: copy script to /usr/local/bin/ledger_backup.sh
# and add crontab entry: 0 2 * * * /usr/local/bin/ledger_backup.sh
# ---------------------------------------------------------------------------
CRONTAB
0 2 * * * /usr/local/bin/ledger_backup.sh >/dev/null 2>&1