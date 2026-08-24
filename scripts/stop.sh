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

echo -e "\033[1;34m[INFO]\033[0m Stopping FynnCloud services ($COMPOSE_FILE)..."
docker compose -f "$COMPOSE_FILE" down
echo -e "\033[1;32m✅ FynnCloud services stopped successfully.\033[0m"
