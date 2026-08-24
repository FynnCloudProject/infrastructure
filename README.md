# FynnCloud Deployment

Deployment configuration and Docker Compose setup for [FynnCloud](https://fynncloud.ch).

## Quick Start

```bash
git clone https://github.com/FynnCloudProject/FynnCloud-Infrastructure.git
cd FynnCloud-Infrastructure

# Generates .env with required keys if missing and starts the containers
./scripts/start.sh
```

Once started, open `http://localhost` (or your server's IP address).

## Stack Overview

| Service | Container Name | Description |
| :--- | :--- | :--- |
| **proxy** | `fynncloud-proxy` | Nginx reverse proxy routing `/api/` to `server` and `/*` to `web` |
| **web** | `fynncloud-web` | Nuxt web frontend |
| **server** | `fynncloud-server` | Swift Vapor REST API server |
| **db** | `fynncloud-db` | PostgreSQL 16 with `pgvector` |
| **redis** | `fynncloud-redis` | Redis cache for sessions, locks, and task queues |
| **eurooffice** *(optional)* | `fynncloud-eurooffice` | Document server for in-browser editing |

## Scripts

| Command | Description |
| :--- | :--- |
| `./scripts/start.sh [prod\|dev]` | Start containers (generates `.env` and missing secrets on first run) |
| `./scripts/stop.sh [prod\|dev]` | Stop running containers |
| `./scripts/logs.sh [service]` | Follow logs (e.g. `./scripts/logs.sh server`) |
| `./scripts/update.sh` | Pull latest images and recreate containers |
| `./scripts/backup-db.sh` | Dump PostgreSQL database to `backups/` |
| `./scripts/restore-db.sh <file.sql.gz>` | Restore PostgreSQL database from backup |

## Configuration

Copy `.env.example` to `.env` to customize the configuration:

```bash
cp .env.example .env
```

### Common Variables

| Variable | Default | Description |
| :--- | :--- | :--- |
| `FRONTEND_URL` | `http://localhost` | Public URL of the web interface |
| `PROXY_PORT` | `80` | Host port for the Nginx proxy |
| `JWT_SECRET` | *(auto-generated)* | Key used to sign JWT authentication tokens |
| `ENCRYPTION_KEY` | *(auto-generated)* | 256-bit key used to encrypt 2FA secrets at rest |
| `DB_PASSWORD` | *(auto-generated)* | Database password for user `fynncloud` |
| `AUTO_MIGRATE` | `true` | Run schema migrations automatically on startup |
| `MAX_CHUNK_SIZE` | `100` | Chunk size in MB for multipart uploads |
| `MAX_BODY_SIZE` | `100` | Max request body size in MB |

## HTTPS / Reverse Proxy

When deploying to production, terminate TLS in front of the containers. 

If using **EuroOffice** for document editing, it runs as a separate service on port `8082` and must be exposed under its own dedicated subdomain (e.g. `office.example.com`) with HTTPS to prevent mixed-content restrictions.

### Caddy Example

```caddyfile
# FynnCloud Web & API
cloud.example.com {
    reverse_proxy localhost:80
}

# EuroOffice Document Server (optional)
office.example.com {
    reverse_proxy localhost:8082
}
```

### Nginx Example

```nginx
# FynnCloud Web & API
server {
    listen 443 ssl http2;
    server_name cloud.example.com;

    ssl_certificate /etc/letsencrypt/live/cloud.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/cloud.example.com/privkey.pem;

    client_max_body_size 500M;

    location / {
        proxy_pass http://127.0.0.1:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# EuroOffice Document Server (optional)
server {
    listen 443 ssl http2;
    server_name office.example.com;

    ssl_certificate /etc/letsencrypt/live/office.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/office.example.com/privkey.pem;

    location / {
        proxy_pass http://127.0.0.1:8082;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## In-Browser Document Editing

EuroOffice allows in-browser editing of `.docx`, `.xlsx`, and `.pptx` documents.

Because the editor is loaded inside an iframe by the browser, it requires its own separate subdomain in production:

1. Point a dedicated subdomain (e.g. `office.example.com`) to your server.
2. Configure your reverse proxy (Caddy/Nginx) to forward that subdomain with TLS to port `8082`.
3. In `.env`, set:
   ```env
   DOCUMENT_SERVER_URL=https://office.example.com
   ```
4. Run `./scripts/start.sh`.

## S3 / Object Storage

By default, uploaded files are stored in the local Docker volume `server_storage`. To use S3-compatible storage instead, configure the S3 variables in `.env`:

```env
S3_BUCKET=my-bucket
AWS_ACCESS_KEY_ID=your_key
AWS_SECRET_ACCESS_KEY=your_secret
AWS_REGION=us-east-1
AWS_ENDPOINT=https://s3.amazonaws.com
```

## Kubernetes (Helm)

A Helm chart is available in `charts/fynncloud`:

```bash
cd charts/fynncloud

helm install fynncloud . \
  --namespace fynncloud \
  --create-namespace \
  --set backend.env.JWT_SECRET="your-jwt-secret" \
  --set backend.env.ENCRYPTION_KEY="your-encryption-key"
```

See [charts/fynncloud/README.md](charts/fynncloud/README.md) for full chart values and options.
