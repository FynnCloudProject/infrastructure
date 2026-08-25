{{/*
Expand the name of the chart.
*/}}
{{- define "fynncloud.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "fynncloud.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "fynncloud.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "fynncloud.labels" -}}
helm.sh/chart: {{ include "fynncloud.chart" . }}
{{ include "fynncloud.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "fynncloud.selectorLabels" -}}
app.kubernetes.io/name: {{ include "fynncloud.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
ServiceAccount name
*/}}
{{- define "fynncloud.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "fynncloud.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Gateway resource name
*/}}
{{- define "fynncloud.gateway.name" -}}
{{- if .Values.gateway.nameOverride }}
{{- .Values.gateway.nameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-gateway" (include "fynncloud.fullname" .) }}
{{- end }}
{{- end }}

{{/*
HTTPRoute resource name
*/}}
{{- define "fynncloud.httpRoute.name" -}}
{{- if .Values.httpRoute.nameOverride }}
{{- .Values.httpRoute.nameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- include "fynncloud.fullname" . }}
{{- end }}
{{- end }}

{{/*
PostgreSQL host
- CNPG Default RW Service: [cluster-name]-rw
- External: .Values.externalPostgresql.host
*/}}
{{- define "fynncloud.postgresql.host" -}}
{{- if .Values.cnpg.enabled }}
{{- printf "%s-%s-rw" (include "fynncloud.fullname" .) .Values.cnpg.name }}
{{- else }}
{{- .Values.externalPostgresql.host }}
{{- end }}
{{- end }}

{{/*
PostgreSQL port
*/}}
{{- define "fynncloud.postgresql.port" -}}
{{- if .Values.cnpg.enabled }}
{{- printf "5432" }}
{{- else }}
{{- .Values.externalPostgresql.port | toString }}
{{- end }}
{{- end }}

{{/*
PostgreSQL username
*/}}
{{- define "fynncloud.postgresql.username" -}}
{{- if .Values.cnpg.enabled }}
{{- .Values.cnpg.bootstrap.initdb.owner }}
{{- else }}
{{- .Values.externalPostgresql.username }}
{{- end }}
{{- end }}

{{/*
PostgreSQL database
*/}}
{{- define "fynncloud.postgresql.database" -}}
{{- if .Values.cnpg.enabled }}
{{- .Values.cnpg.bootstrap.initdb.database }}
{{- else }}
{{- .Values.externalPostgresql.database }}
{{- end }}
{{- end }}

{{/*
PostgreSQL Secret Name
- CNPG Default App Secret: [cluster-name]-app
- External: existingSecret or managed secret
*/}}
{{- define "fynncloud.postgresql.secretName" -}}
{{- if .Values.cnpg.enabled }}
{{- printf "%s-%s-app" (include "fynncloud.fullname" .) .Values.cnpg.name }}
{{- else if .Values.externalPostgresql.existingSecret }}
{{- .Values.externalPostgresql.existingSecret }}
{{- else }}
{{- printf "%s-secrets" (include "fynncloud.fullname" .) }}
{{- end }}
{{- end }}

{{/*
PostgreSQL Password Key
- CNPG App Secret has 'password' key
- External/Managed has 'postgres-password'
*/}}
{{- define "fynncloud.postgresql.secretKey" -}}
{{- if .Values.cnpg.enabled }}
{{- printf "password" }}
{{- else }}
{{- printf "postgres-password" }}
{{- end }}
{{- end }}

{{/*
JWT secret name
*/}}
{{- define "fynncloud.jwt.secretName" -}}
{{- if .Values.backend.existingSecret }}
{{- .Values.backend.existingSecret }}
{{- else }}
{{- printf "%s-secrets" (include "fynncloud.fullname" .) }}
{{- end }}
{{- end }}

{{/*
PostgreSQL SSL Mode
*/}}
{{- define "fynncloud.postgresql.sslMode" -}}
{{- if .Values.cnpg.enabled }}
{{- .Values.cnpg.sslMode }}
{{- else }}
{{- .Values.externalPostgresql.sslMode }}
{{- end }}
{{- end }}

{{/*
Image pull secrets - merges global with any per-component secrets if needed
*/}}
{{- define "fynncloud.imagePullSecrets" -}}
{{- with .Values.global.imagePullSecrets }}
imagePullSecrets:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}

{{/*
Return the storageClass name prioritizing component override over global setting.
Usage: {{ include "fynncloud.storageClass" (dict "root" $ "componentStorageClass" .Values.backend.storage.storageClass) }}
*/}}
{{- define "fynncloud.storageClass" -}}
{{- if .componentStorageClass -}}
{{- .componentStorageClass -}}
{{- else if .root.Values.global.storageClass -}}
{{- .root.Values.global.storageClass -}}
{{- end -}}
{{- end }}

{{/*
Busybox image for init containers
*/}}
{{- define "fynncloud.busyboxImage" -}}
{{- default "busybox:1.36" .Values.global.busyboxImage -}}
{{- end }}
{{/*
Redis host
*/}}
{{- define "fynncloud.redis.host" -}}
{{- if .Values.redis.enabled }}
{{- printf "%s-redis" (include "fynncloud.fullname" .) }}
{{- else if .Values.externalRedis.host }}
{{- .Values.externalRedis.host }}
{{- else }}
{{- printf "%s-redis" (include "fynncloud.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Redis port
*/}}
{{- define "fynncloud.redis.port" -}}
{{- if .Values.redis.enabled }}
{{- printf "6379" }}
{{- else if .Values.externalRedis.port }}
{{- .Values.externalRedis.port | toString }}
{{- else }}
{{- printf "6379" }}
{{- end }}
{{- end }}

{{/*
Redis URL
*/}}
{{- define "fynncloud.redis.url" -}}
{{- if .Values.redis.enabled }}
{{- printf "redis://%s-redis:6379" (include "fynncloud.fullname" .) }}
{{- else if .Values.externalRedis.url }}
{{- .Values.externalRedis.url }}
{{- else if .Values.externalRedis.host }}
{{- printf "redis://%s:%s" (include "fynncloud.redis.host" .) (include "fynncloud.redis.port" .) }}
{{- else }}
{{- printf "" }}
{{- end }}
{{- end }}
