#!/usr/bin/env bash
set -e

MODE="prod"
SERVICE=""

# Parse arguments: ./scripts/logs.sh [prod|dev] [service] OR ./scripts/logs.sh [service]
if [ "$1" = "dev" ] || [ "$1" = "development" ]; then
    MODE="dev"
    SERVICE="${2:-}"
elif [ "$1" = "prod" ] || [ "$1" = "production" ]; then
    MODE="prod"
    SERVICE="${2:-}"
else
    SERVICE="${1:-}"
fi

if [ "$MODE" = "dev" ]; then
    COMPOSE_FILE="docker-compose.dev.yml"
else
    COMPOSE_FILE="docker-compose.yml"
fi

if [ -z "$SERVICE" ]; then
    docker compose -f "$COMPOSE_FILE" logs -f
else
    docker compose -f "$COMPOSE_FILE" logs -f "$SERVICE"
fi
