#!/usr/bin/env bash
set -e

MODE="${1:-prod}"
if [ "$MODE" = "dev" ] || [ "$MODE" = "development" ]; then
    COMPOSE_FILE="docker-compose.dev.yml"
else
    COMPOSE_FILE="docker-compose.yml"
fi

if [ ! -f "$COMPOSE_FILE" ]; then
    echo -e "\033[1;31m[ERROR]\033[0m Compose file not found: $COMPOSE_FILE"
    exit 1
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="backups"
BACKUP_FILE="${BACKUP_DIR}/fynncloud_${MODE}_backup_${TIMESTAMP}.sql"

mkdir -p "$BACKUP_DIR"

echo -e "\033[1;34m[INFO]\033[0m Creating PostgreSQL backup..."
docker compose -f "$COMPOSE_FILE" exec -T db pg_dump -U fynncloud fynncloud > "$BACKUP_FILE"
gzip "$BACKUP_FILE"

echo -e "\033[1;32m✅ Backup created successfully:\033[0m ${BACKUP_FILE}.gz"
