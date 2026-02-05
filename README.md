# FynnCloud Infrastructure

Deployment configuration for FynnCloud.

## Quick Start

```bash
# Configure
cp .env.example .env
nano .env  # Set at least DB_PASSWORD and JWT_SECRET

# Start
./scripts/start.sh
```

## Stack
- Nginx reverse proxy (routes /api to backend, /* to frontend)
- Backend API (Swift Vapor)
- Frontend (Nuxt.js) built as static files, served by Nginx
- PostgreSQL database

## Commands
- `./scripts/start.sh {dev|prod}` - Start services
- `./scripts/stop.sh {dev|prod}` - Stop services
- `./scripts/logs.sh {dev|prod}` - View logs
- `./scripts/backup-db.sh {dev|prod}` - Backup database
