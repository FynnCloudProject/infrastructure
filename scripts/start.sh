#!/bin/bash
set -e

MODE="${1:-prod}"
COMPOSE_FILE="docker-compose.${MODE}.yml"

# --- Helper Functions ---

log() { echo -e "\033[1;34m[INFO]\033[0m $1"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m $1"; }
error() { echo -e "\033[1;31m[ERROR]\033[0m $1"; exit 1; }

# Ensure openssl is installed
if ! command -v openssl &> /dev/null; then
    error "openssl is required but not installed."
fi

# Function to safely inject/replace secrets
set_secret() {
    local key=$1
    local env_file=".env"
    
    # Check if key exists in file
    if ! grep -q "^$key=" "$env_file"; then
        # Key missing entirely? Append it.
        echo "$key=$(openssl rand -base64 32)" >> "$env_file"
        log "Added missing secret: $key"
    else
        # Key exists? Check if it's empty or contains "changeme"
        local current_val=$(grep "^$key=" "$env_file" | cut -d '=' -f2-)
        if [[ -z "$current_val" ]] || [[ "$current_val" == "changeme"* ]]; then
            local new_val=$(openssl rand -base64 32)
            # Use a portable sed approach (works on Linux/GNU and macOS/BSD)
            sed -i.bak "s|^$key=.*|$key=$new_val|" "$env_file" && rm "${env_file}.bak"
            log "Updated default/empty secret: $key"
        fi
    fi
}

# --- Initialization ---

if [ ! -f "$COMPOSE_FILE" ]; then
    error "File not found: $COMPOSE_FILE\nUsage: $0 [prod|dev]"
fi

if [ ! -f .env ]; then
    warn "No .env file found. Cloning from .env.example..."
    if [ -f .env.example ]; then
        cp .env.example .env
    else
        touch .env
        warn "No .env.example found. Creating empty .env..."
    fi
fi

# --- Secret Injection ---
log "Validating security keys..."
set_secret "DB_PASSWORD"
set_secret "JWT_SECRET"

# --- Docker Operations ---
log "Starting FynnCloud ($MODE mode)"
docker compose -f "$COMPOSE_FILE" up -d

log "Waiting for services to stabilize..."
sleep 10

echo ""
echo "📊 Service Status:"
docker compose -f "$COMPOSE_FILE" ps

echo ""
echo -e "\033[1;32m✅ FynnCloud is up!\033[0m"
if [ "$MODE" = "prod" ]; then
    echo "   URL: http://localhost"
else
    echo "   Backend:  http://localhost:$(grep BACKEND_PORT .env | cut -d'=' -f2 || echo 8080)"
    echo "   Frontend: http://localhost:$(grep FRONTEND_PORT .env | cut -d'=' -f2 || echo 3000)"
fi