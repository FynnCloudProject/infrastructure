#!/bin/bash
MODE="${1:-prod}"
docker compose -f "docker-compose.${MODE}.yml" down
echo "✅ Stopped"
