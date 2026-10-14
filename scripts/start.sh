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

# Helper to read a value from .env
get_env_val() {
    local key=$1
    local env_file=".env"
    grep "^$key=" "$env_file" 2>/dev/null | head -n 1 | cut -d '=' -f2- | tr -d '\r'
}

# Function to safely generate and inject/replace secrets in .env
set_secret() {
    local key=$1
    local env_file=".env"
    
    if ! grep -q "^$key=" "$env_file"; then
        local new_val=$(openssl rand -base64 32 | tr -d '\n\r')
        echo "$key=$new_val" >> "$env_file"
        log "Generated secret for $key"
    else
        local current_val=$(get_env_val "$key")
        if [[ -z "$current_val" ]] || [[ "$current_val" == "changeme"* ]]; then
            local new_val=$(openssl rand -base64 32 | tr -d '\n\r')
            sed -i.bak "s|^$key=.*|$key=$new_val|" "$env_file" && rm -f "${env_file}.bak"
            log "Generated secret for $key"
        fi
    fi
}

# Safely handle canonical/legacy pairs without clobbering existing secrets
set_secret_pair() {
    local canonical=$1
    local legacy=$2
    local env_file=".env"

    local c_val=$(get_env_val "$canonical")
    local l_val=$(get_env_val "$legacy")

    # 1. Canonical already has a valid secret
    if [[ -n "$c_val" ]] && [[ "$c_val" != "changeme"* ]]; then
        return 0
    fi

    # 2. Canonical is missing/empty, but legacy has an existing valid secret
    if [[ -n "$l_val" ]] && [[ "$l_val" != "changeme"* ]]; then
        if grep -q "^$canonical=" "$env_file"; then
            sed -i.bak "s|^$canonical=.*|$canonical=$l_val|" "$env_file" && rm -f "${env_file}.bak"
            log "Migrated existing $legacy to $canonical"
        fi
        return 0
    fi

    # 3. Neither has a valid secret: generate one for canonical
    set_secret "$canonical"
}

# --- Pre-flight Checks ---
if ! command -v docker &> /dev/null; then
    error "docker is required, but is not installed or not in PATH."
fi

if ! docker info &> /dev/null; then
    error "Docker daemon is not running or accessible. Please start Docker first."
fi

if ! command -v openssl &> /dev/null; then
    error "openssl is required for secret generation, but is not installed."
fi

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
set_secret_pair "AUTH_JWT_SECRET" "JWT_SECRET"
set_secret_pair "SECURITY_ENCRYPTION_KEY" "ENCRYPTION_KEY"
set_secret_pair "DOCS_JWT_SECRET" "EUROOFFICE_JWT_SECRET"

# --- Start Docker Services ---
log "Starting FynnCloud ($MODE mode)..."
docker compose -f "$COMPOSE_FILE" up -d

log "Waiting for services to become healthy..."
sleep 5

echo ""
echo "📊 Service Status:"
docker compose -f "$COMPOSE_FILE" ps

# Read port configuration from .env if present
PROXY_PORT=$(get_env_val "PROXY_PORT")
[ -z "$PROXY_PORT" ] && PROXY_PORT="80"

echo ""
echo -e "\033[1;32m🚀 FynnCloud is up and running!\033[0m"
if [ "$MODE" = "prod" ]; then
    echo "   Web Application: http://localhost:${PROXY_PORT}"
else
    SERVER_PORT=$(get_env_val "SERVER_PORT")
    [ -z "$SERVER_PORT" ] && SERVER_PORT=$(get_env_val "BACKEND_PORT")
    [ -z "$SERVER_PORT" ] && SERVER_PORT="8080"

    WEB_PORT=$(get_env_val "FRONTEND_PORT")
    [ -z "$WEB_PORT" ] && WEB_PORT="3000"

    echo "   Proxy:   http://localhost:${PROXY_PORT}"
    echo "   Web:     http://localhost:${WEB_PORT}"
    echo "   Server:  http://localhost:${SERVER_PORT}"
    echo "   Adminer: http://localhost:8081"
fi
echo ""
echo "View container logs with: ./scripts/logs.sh"