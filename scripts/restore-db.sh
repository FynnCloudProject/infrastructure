#!/usr/bin/env bash
set -e

BACKUP_FILE="$1"
MODE="${2:-prod}"

if [ "$MODE" = "dev" ] || [ "$MODE" = "development" ]; then
    COMPOSE_FILE="docker-compose.dev.yml"
else
    COMPOSE_FILE="docker-compose.yml"
fi

if [ -z "$BACKUP_FILE" ]; then
    echo "Usage: $0 <backup-file.sql.gz> [prod|dev]"
    echo ""
    echo "Available backups in backups/:"
    ls -lh backups/*.sql.gz 2>/dev/null || echo "  (No backups found in backups/)"
    exit 1
fi

if [ ! -f "$BACKUP_FILE" ]; then
    echo -e "\033[1;31m[ERROR]\033[0m Backup file not found: $BACKUP_FILE"
    exit 1
fi

echo -e "\033[1;33m⚠️  WARNING: This operation will overwrite all existing database data!\033[0m"
read -p "Are you sure you want to continue? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Restore operation aborted."
    exit 0
fi

echo -e "\033[1;34m[INFO]\033[0m Restoring database from $BACKUP_FILE..."
if [[ "$BACKUP_FILE" == *.gz ]]; then
    gunzip -c "$BACKUP_FILE" | docker compose -f "$COMPOSE_FILE" exec -T db psql -U fynncloud fynncloud
else
    docker compose -f "$COMPOSE_FILE" exec -T db psql -U fynncloud fynncloud < "$BACKUP_FILE"
fi

echo -e "\033[1;32m✅ Database restored successfully!\033[0m"
