#!/bin/bash
MODE="${1:-prod}"
COMPOSE_FILE="docker-compose.${MODE}.yml"
set -e
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="backups/fynncloud_${MODE}_backup_$TIMESTAMP.sql"
mkdir -p backups
echo "💾 Creating backup..."
docker compose -f $COMPOSE_FILE exec -T db pg_dump -U fynncloud fynncloud > "$BACKUP_FILE"
gzip "$BACKUP_FILE"
echo "✅ Backup created: ${BACKUP_FILE}.gz"
