#!/bin/bash
# Lidi Studio — restore script
# Usage: ./restore.sh [--snapshot <id>] [--target /tmp/restore] [--apply]
#
# Without --apply: extracts snapshot to /tmp/lidi-restore for inspection.
# With --apply:    docker compose down → overwrites live volumes → docker compose up.
#
# REQUIRES /opt/lidi/.env to be readable by the invoking user.

set -euo pipefail

# shellcheck disable=SC1091
source /opt/lidi/.env

SNAPSHOT="latest"
TARGET="/tmp/lidi-restore"
APPLY=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --snapshot) SNAPSHOT="$2"; shift 2 ;;
    --target)   TARGET="$2"; shift 2 ;;
    --apply)    APPLY=1; shift ;;
    --help|-h)
      echo "Usage: $0 [--snapshot <id>] [--target <dir>] [--apply]"
      echo ""
      echo "  --snapshot   Restic snapshot id (default: latest)"
      echo "  --target     Local extraction path (default: /tmp/lidi-restore)"
      echo "  --apply      Actually overwrite live volumes (default: dry-run)"
      exit 0
      ;;
    *) echo "Unknown arg: $1"; exit 2 ;;
  esac
done

export RESTIC_REPOSITORY RESTIC_PASSWORD
export AWS_ACCESS_KEY_ID="$R2_ACCESS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="$R2_SECRET_ACCESS_KEY"

echo "=== Available snapshots ==="
restic snapshots --tag lidi-studio | head -20

echo ""
echo "Will restore snapshot: $SNAPSHOT"
echo "To target:             $TARGET"
if [ "$APPLY" -eq 1 ]; then
  echo "MODE: APPLY (will overwrite live volumes — REQUIRES docker compose down)"
else
  echo "MODE: dry-run (extract to $TARGET for inspection only)"
fi

read -r -p "Proceed? Type 'yes' to confirm: " confirm
if [ "$confirm" != "yes" ]; then
  echo "Aborted."
  exit 0
fi

mkdir -p "$TARGET"
restic restore "$SNAPSHOT" --target "$TARGET"

if [ "$APPLY" -eq 1 ]; then
  echo "Stopping stack..."
  cd /opt/lidi/infra
  docker compose down

  echo "Restoring volumes..."
  for vol in postgres_data ghost_content docuseal_data nocodb_data uptime_kuma_data; do
    if [ -d "$TARGET/var/lib/docker/volumes/infra_$vol" ]; then
      echo "  → $vol"
      rsync -a --delete \
        "$TARGET/var/lib/docker/volumes/infra_$vol/" \
        "/var/lib/docker/volumes/infra_$vol/"
    fi
  done

  echo "Restoring postgres logical dumps..."
  docker compose up -d postgres
  sleep 10  # let postgres start

  for db in "$POSTGRES_DB_GHOST" "$POSTGRES_DB_CALCOM" "$POSTGRES_DB_DOCUSEAL" "$POSTGRES_DB_NOCODB" "$POSTGRES_DB_UMAMI"; do
    DUMP_FILE="$TARGET/var/lib/lidi/backup-staging/${db}.sql.gz"
    if [ -f "$DUMP_FILE" ]; then
      echo "  → restoring $db"
      gunzip -c "$DUMP_FILE" \
        | docker exec -i lidi-postgres pg_restore -U "$POSTGRES_USER" -d "$db" --clean --if-exists
    else
      echo "  ! no dump found for $db at $DUMP_FILE"
    fi
  done

  echo "Bringing stack back up..."
  docker compose up -d

  echo ""
  echo "Restore complete. Run scripts/health-check.sh to verify."
else
  echo ""
  echo "Snapshot extracted to $TARGET. Inspect manually."
  echo "Run again with --apply to overwrite live volumes."
fi
