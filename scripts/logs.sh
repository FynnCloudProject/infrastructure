#!/bin/bash
MODE="${1:-prod}"
SERVICE="${2:-}"
if [ -z "$SERVICE" ]; then
    docker compose -f "docker-compose.${MODE}.yml" logs -f
else
    docker compose -f "docker-compose.${MODE}.yml" logs -f "$SERVICE"
fi
