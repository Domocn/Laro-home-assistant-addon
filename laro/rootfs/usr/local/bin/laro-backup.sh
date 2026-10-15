#!/bin/bash
# Called by Supervisor around Home Assistant backups (config.yaml backup_pre/backup_post).
# "pre" writes a consistent SQL dump into /data so it is included in the backup even if
# the raw Postgres files are captured mid-write; "post" removes it again.
set -euo pipefail
DUMP=/data/laro-db-backup.sql.gz
case "${1:-}" in
  pre)
    echo "[laro-backup] Dumping database to ${DUMP}..."
    su - postgres -c "pg_dump -h /var/run/postgresql -d laro --no-owner" | gzip -c > "${DUMP}.tmp"
    mv "${DUMP}.tmp" "${DUMP}"
    chmod 600 "${DUMP}"
    echo "[laro-backup] Done ($(du -h "${DUMP}" | cut -f1))."
    ;;
  post)
    rm -f "${DUMP}" "${DUMP}.tmp"
    ;;
  *)
    echo "usage: $0 pre|post" >&2; exit 2 ;;
esac
