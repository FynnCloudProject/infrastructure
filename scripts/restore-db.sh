#!/bin/bash
set -e
MODE="${1:-prod}"
COMPOSE_FILE="docker-compose.${MODE}.yml"
BACKUP_FILE="$1"
if [ -z "$BACKUP_FILE" ]; then
    echo "Usage: $0 <backup-file.sql.gz>"
    ls -lh backups/*.sql.gz 2>/dev/null || echo "No backups found"
    exit 1
fi
echo "⚠️  This will overwrite the database!"
read -p "Continue? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Aborted"
    exit 0
fi
echo "🔄 Restoring..."
if [[ $BACKUP_FILE == *.gz ]]; then
    gunzip -c "$BACKUP_FILE" | docker compose -f $COMPOSE_FILE exec -T db psql -U fynncloud fynncloud
else
    docker compose -f $COMPOSE_FILE exec -T db psql -U fynncloud fynncloud < "$BACKUP_FILE"
fi
echo "✅ Restored!"
