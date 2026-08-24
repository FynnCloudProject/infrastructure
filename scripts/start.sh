#!/usr/bin/env bash
set -e

MODE="${1:-prod}"
if [ "$MODE" = "dev" ] || [ "$MODE" = "development" ]; then
    COMPOSE_FILE="docker-compose.dev.yml"
    MODE="dev"
else
    COMPOSE_FILE="docker-compose.yml"
    MODE="prod"
fi

# --- Helper Functions ---
log() { echo -e "\033[1;34m[INFO]\033[0m $1"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m $1"; }
success() { echo -e "\033[1;32m[SUCCESS]\033[0m $1"; }
error() { echo -e "\033[1;31m[ERROR]\033[0m $1"; exit 1; }

# Ensure openssl is installed
if ! command -v openssl &> /dev/null; then
    error "openssl is required for secret generation, but is not installed."
fi

# Function to safely generate and inject/replace secrets in .env
set_secret() {
    local key=$1
    local env_file=".env"
    
    if ! grep -q "^$key=" "$env_file"; then
        local new_val=$(openssl rand -base64 32 | tr -d '\n\r')
        echo "$key=$new_val" >> "$env_file"
        log "Generated secret for $key"
    else
        local current_val=$(grep "^$key=" "$env_file" | head -n 1 | cut -d '=' -f2-)
        if [[ -z "$current_val" ]] || [[ "$current_val" == "changeme"* ]]; then
            local new_val=$(openssl rand -base64 32 | tr -d '\n\r')
            sed -i.bak "s|^$key=.*|$key=$new_val|" "$env_file" && rm -f "${env_file}.bak"
            log "Generated secret for $key"
        fi
    fi
}

# --- Initialization ---
if [ ! -f "$COMPOSE_FILE" ]; then
    error "Compose file not found: $COMPOSE_FILE"
fi

if [ ! -f .env ]; then
    warn "No .env file found. Copying default configuration from .env.example..."
    if [ -f .env.example ]; then
        cp .env.example .env
    else
        touch .env
    fi
fi

# --- Secret Generation ---
log "Validating security keys..."
set_secret "DB_PASSWORD"
set_secret "JWT_SECRET"
set_secret "ENCRYPTION_KEY"
set_secret "EUROOFFICE_JWT_SECRET"

# --- Start Docker Services ---
log "Starting FynnCloud ($MODE mode)..."
docker compose -f "$COMPOSE_FILE" up -d

log "Waiting for services to become healthy..."
sleep 5

echo ""
echo "📊 Service Status:"
docker compose -f "$COMPOSE_FILE" ps

# Read port configuration from .env if present
PROXY_PORT=$(grep "^PROXY_PORT=" .env 2>/dev/null | cut -d'=' -f2 | tr -d ' ' || echo "80")
[ -z "$PROXY_PORT" ] && PROXY_PORT="80"

echo ""
echo -e "\033[1;32m🚀 FynnCloud is up and running!\033[0m"
if [ "$MODE" = "prod" ]; then
    echo "   Web Application: http://localhost:${PROXY_PORT}"
else
    SERVER_PORT=$(grep "^SERVER_PORT=" .env 2>/dev/null | cut -d'=' -f2 | tr -d ' ' || echo "8080")
    WEB_PORT=$(grep "^FRONTEND_PORT=" .env 2>/dev/null | cut -d'=' -f2 | tr -d ' ' || echo "3000")
    echo "   Proxy:   http://localhost:${PROXY_PORT}"
    echo "   Web:     http://localhost:${WEB_PORT:-3000}"
    echo "   Server:  http://localhost:${SERVER_PORT:-8080}"
    echo "   Adminer: http://localhost:8081"
fi
echo ""
echo "View container logs with: ./scripts/logs.sh"