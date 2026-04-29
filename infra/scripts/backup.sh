#!/bin/bash
# Lidi Studio — backup script
# Runs nightly via cron at 03:00 America/Anchorage.
# Strategy: pg_dump of each logical DB → restic snapshot of dumps + volumes + .env → R2.
# Retention: 30 daily / 12 monthly / 5 yearly.
# See /docs/platform-architecture-v1.md §2.15 + §11.

set -euo pipefail

# Load env
# shellcheck disable=SC1091
source /opt/lidi/.env

# Paths
BACKUP_STAGING="/var/lib/lidi/backup-staging"
LOG="/var/log/lidi/backup.log"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Ensure directories
mkdir -p "$BACKUP_STAGING" "$(dirname "$LOG")"

log() {
  echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $1" | tee -a "$LOG"
}

notify_telegram() {
  if [ -n "${TELEGRAM_BOT_TOKEN:-}" ] && [ -n "${TELEGRAM_CHAT_ID:-}" ]; then
    curl -sS -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
      -d "chat_id=${TELEGRAM_CHAT_ID}" \
      -d "text=$1" >/dev/null || true
  fi
}

trap 'log "BACKUP FAILED at $TIMESTAMP"; notify_telegram "🔴 Lidi Studio backup FAILED at $TIMESTAMP"; exit 1' ERR

log "===== Backup started: $TIMESTAMP ====="

# ──────────────── Stage 1: Postgres dumps ────────────────
log "Dumping Postgres databases..."
for db in "$POSTGRES_DB_GHOST" "$POSTGRES_DB_CALCOM" "$POSTGRES_DB_DOCUSEAL" "$POSTGRES_DB_NOCODB" "$POSTGRES_DB_UMAMI"; do
  log "  → $db"
  docker exec lidi-postgres pg_dump -U "$POSTGRES_USER" -Fc "$db" \
    | gzip -9 > "$BACKUP_STAGING/${db}.sql.gz"
done

# ──────────────── Stage 2: Restic snapshot ────────────────
log "Running restic backup..."
export RESTIC_REPOSITORY RESTIC_PASSWORD
export AWS_ACCESS_KEY_ID="$R2_ACCESS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="$R2_SECRET_ACCESS_KEY"

restic backup \
  --tag "lidi-studio" \
  --tag "$(date -u +%Y-%m-%d)" \
  /var/lib/docker/volumes/infra_postgres_data \
  /var/lib/docker/volumes/infra_ghost_content \
  /var/lib/docker/volumes/infra_docuseal_data \
  /var/lib/docker/volumes/infra_nocodb_data \
  /var/lib/docker/volumes/infra_uptime_kuma_data \
  "$BACKUP_STAGING" \
  /opt/lidi/.env \
  2>&1 | tee -a "$LOG"

# ──────────────── Stage 3: Retention policy ────────────────
log "Applying retention policy (30 daily / 12 monthly / 5 yearly)..."
restic forget \
  --keep-daily 30 \
  --keep-monthly 12 \
  --keep-yearly 5 \
  --prune \
  2>&1 | tee -a "$LOG"

# ──────────────── Stage 4: Integrity sample check ────────────────
log "Verifying repository integrity..."
restic check --read-data-subset=5% 2>&1 | tee -a "$LOG"

# ──────────────── Stage 5: Cleanup staging ────────────────
log "Cleaning staging..."
rm -rf "${BACKUP_STAGING:?}"/*

log "===== Backup completed: $(date -u +"%Y-%m-%dT%H:%M:%SZ") ====="
notify_telegram "✅ Lidi Studio backup completed at $(date -u +"%Y-%m-%dT%H:%M:%SZ")"

exit 0

# Cron entry (add via root crontab):
#   0 3 * * * /opt/lidi/infra/scripts/backup.sh
