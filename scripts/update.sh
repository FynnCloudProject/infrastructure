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

echo -e "\033[1;34m[INFO]\033[0m Pulling latest container images..."
docker compose -f "$COMPOSE_FILE" pull

echo -e "\033[1;34m[INFO]\033[0m Recreating containers with new images..."
docker compose -f "$COMPOSE_FILE" up -d --remove-orphans

echo -e "\033[1;32m✅ FynnCloud updated successfully!\033[0m"
docker compose -f "$COMPOSE_FILE" ps
