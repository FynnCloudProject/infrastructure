# FynnCloud Helm Chart

[![Helm Chart Version](https://img.shields.io/badge/Helm%20Chart-v0.4.1-blue.svg)](https://github.com/FynnCloudProject)
[![Kubernetes Version](https://img.shields.io/badge/Kubernetes-%3E%3D1.27.0-brightgreen.svg)](https://kubernetes.io)

Official Helm chart for deploying **FynnCloud** — high-performance, self-hosted cloud storage on Kubernetes.

---

## 🚀 Features

- **Decoupled Architecture**: High-availability Swift server (`fynncloud-server`) and Nuxt 3 web frontend (`fynncloud-web`).
- **Database Operations**: Integrated CloudNativePG operator support with automated failover or connection to external PostgreSQL instances.
- **Modern Networking**: Gateway API (`Gateway` and `HTTPRoute`) support alongside legacy `Ingress` compatibility.
- **GitOps Ready**: Built-in support for ArgoCD hooks and automated schema migrations.
- **Security & Reliability**: Horizontal Pod Autoscaling (HPA), Pod Disruption Budgets (PDB), and NetworkPolicies out of the box.

---

## 📋 Prerequisites

- **Kubernetes**: `>= 1.27.0`
- **Helm**: `v3.8.0+`
- **CloudNativePG Operator** *(optional, default)*: Required if `cnpg.enabled=true`. [Install Guide](https://cloudnative-pg.io/documentation/current/installation_upgrade/)
- **Gateway API CRDs / Controller** *(optional)*: Required if `gateway.enabled=true` or `httpRoute.enabled=true`.

---

## 📦 Quick Start

### 1. Add/Fetch the Chart

```bash
# Clone the repository or navigate to the charts folder
cd charts/fynncloud
```

### 2. Install the Chart

```bash
helm install fynncloud . \
  --namespace fynncloud \
  --create-namespace \
  --set server.env.JWT_SECRET="super-secret-jwt-key-change-me" \
  --set server.env.ENCRYPTION_KEY="super-secret-encryption-key-change-me"
```

---

## ⚙️ Key Configuration Scenarios

### Scenario A: CloudNativePG Database (Default)

The chart provisions a 3-instance PostgreSQL cluster managed by CloudNativePG:

```yaml
cnpg:
  enabled: true
  instances: 3
  storage:
    size: 10Gi
    storageClass: "standard"
```

### Scenario B: External PostgreSQL (RDS, Cloud SQL, Self-Managed)

Disable CNPG and supply connection details for an external database:

```yaml
cnpg:
  enabled: false

externalPostgresql:
  host: "postgres.internal.example.com"
  port: 5432
  username: "fynncloud"
  database: "fynncloud"
  existingSecret: "fynncloud-db-credentials" # Contains key `postgres-password`
```

### Scenario C: Gateway API (Recommended)

To route traffic using Kubernetes Gateway API:

```yaml
gateway:
  enabled: true
  gatewayClassName: "eg" # e.g., Envoy Gateway, Istio, Cilium

httpRoute:
  enabled: true
  hostnames:
    - "cloud.example.com"
```

### Scenario D: Legacy Ingress

To use an NGINX or Traefik Ingress controller:

```yaml
ingress:
  enabled: true
  className: "nginx"
  hosts:
    - host: "cloud.example.com"
      paths:
        - path: /api
          pathType: Prefix
          service: server
        - path: /
          pathType: Prefix
          service: web
```

---

## 📊 Configuration Parameters

| Parameter | Description | Default |
| :--- | :--- | :--- |
| `global.storageClass` | Default storage class for all PVCs | `""` |
| `global.busyboxImage` | Container image used for readiness init containers | `"busybox:1.36"` |
| `serviceAccount.create` | Create a ServiceAccount for pods | `true` |
| `cnpg.enabled` | Deploy CloudNativePG PostgreSQL cluster | `true` |
| `cnpg.instances` | Number of database replicas | `3` |
| `server.enabled` | Deploy server server | `true` |
| `server.replicas` | Number of server pod replicas | `3` |
| `server.image.repository` | Container image repository for server | `ghcr.io/fynncloudproject/server` |
| `server.image.tag` | Container image tag for server | `latest` |
| `server.storage.enabled` | Enable PVC for local binary/file storage | `true` |
| `server.storage.size` | Storage capacity for PVC | `"5Gi"` |
| `server.env.JWT_SECRET` | Secret key for JWT signing | `"changeme"` |
| `server.env.ENCRYPTION_KEY` | Key for encrypting 2FA secrets at rest. Required, permanent — changing it makes stored 2FA secrets undecryptable | `"changeme"` |
| `web.enabled` | Deploy web frontend | `true` |
| `web.replicas` | Number of web pod replicas | `1` |
| `web.image.repository` | Container image repository for web | `ghcr.io/fynncloudproject/web` |
| `web.image.tag` | Container image tag for web | `latest` |
| `gateway.enabled` | Provision Gateway API Gateway resource | `false` |
| `httpRoute.enabled` | Provision Gateway API HTTPRoute resource | `false` |
| `ingress.enabled` | Provision Ingress resource | `false` |
| `autoscaling.server.enabled` | Enable Horizontal Pod Autoscaler for server | `false` |
| `networkPolicy.enabled` | Provision isolation NetworkPolicies | `false` |

---

## 🔍 Validation & Linting

Verify template rendering locally:

```bash
helm lint .
helm template my-release . --debug
```
