#!/usr/bin/with-contenv bash
# shellcheck shell=bash
# Laro Home Assistant Add-on startup script

set -e

CONFIG_PATH=/data/options.json

log() {
    echo "[Laro] $1"
}

log "Starting Laro Home Assistant Add-on..."

# Persist JWT across restarts: load existing secret first, only generate if missing.
load_or_create_jwt_secret() {
    local from_options="$1"
    if [ -n "$from_options" ]; then
        echo "$from_options" > /data/jwt_secret
        echo "$from_options"
        return
    fi
    if [ -f /data/jwt_secret ] && [ -s /data/jwt_secret ]; then
        cat /data/jwt_secret
        return
    fi
    log "Generating JWT secret..."
    local generated
    generated=$(head -c 64 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 64)
    echo "$generated" > /data/jwt_secret
    echo "$generated"
}

# Read configuration from Home Assistant options
if [ -f "$CONFIG_PATH" ]; then
    log "Reading configuration from Home Assistant..."

    JWT_SECRET=$(load_or_create_jwt_secret "$(jq -r '.jwt_secret // empty' "$CONFIG_PATH")")

    LLM_PROVIDER=$(jq -r '.llm_provider // "embedded"' "$CONFIG_PATH")
    OLLAMA_URL=$(jq -r '.ollama_url // "http://homeassistant.local:11434"' "$CONFIG_PATH")
    OLLAMA_MODEL=$(jq -r '.ollama_model // "llama3"' "$CONFIG_PATH")
    OPENAI_API_KEY=$(jq -r '.openai_api_key // empty' "$CONFIG_PATH")
    ANTHROPIC_API_KEY=$(jq -r '.anthropic_api_key // empty' "$CONFIG_PATH")
    GOOGLE_AI_API_KEY=$(jq -r '.google_ai_api_key // empty' "$CONFIG_PATH")

    EMAIL_ENABLED=$(jq -r '.email_enabled // "false"' "$CONFIG_PATH")
    SMTP_SERVER=$(jq -r '.smtp_server // empty' "$CONFIG_PATH")
    SMTP_PORT=$(jq -r '.smtp_port // "587"' "$CONFIG_PATH")
    SMTP_USERNAME=$(jq -r '.smtp_username // empty' "$CONFIG_PATH")
    SMTP_PASSWORD=$(jq -r '.smtp_password // empty' "$CONFIG_PATH")
    SMTP_FROM_EMAIL=$(jq -r '.smtp_from_email // empty' "$CONFIG_PATH")

    ENABLE_REGISTRATION=$(jq -r '.enable_registration // "true"' "$CONFIG_PATH")
    GOOGLE_CLIENT_ID=$(jq -r '.google_client_id // empty' "$CONFIG_PATH")
    GOOGLE_CLIENT_SECRET=$(jq -r '.google_client_secret // empty' "$CONFIG_PATH")
    GITHUB_CLIENT_ID=$(jq -r '.github_client_id // empty' "$CONFIG_PATH")
    GITHUB_CLIENT_SECRET=$(jq -r '.github_client_secret // empty' "$CONFIG_PATH")

    POSTGRES_MAX_CONNECTIONS=$(jq -r '.postgres_max_connections // "100"' "$CONFIG_PATH")
    POSTGRES_SHARED_BUFFERS=$(jq -r '.postgres_shared_buffers // "256MB"' "$CONFIG_PATH")

    REDIS_MAXMEMORY=$(jq -r '.redis_maxmemory // "256mb"' "$CONFIG_PATH")

    CELERY_CONCURRENCY=$(jq -r '.celery_concurrency // "2"' "$CONFIG_PATH")
    ENABLE_FLOWER=$(jq -r '.enable_flower_dashboard // "true"' "$CONFIG_PATH")

    DEBUG_MODE=$(jq -r '.debug_mode // "false"' "$CONFIG_PATH")
else
    log "No configuration file found, using defaults..."
    JWT_SECRET=$(load_or_create_jwt_secret "")
    LLM_PROVIDER="embedded"
    OLLAMA_URL="http://homeassistant.local:11434"
    OLLAMA_MODEL="llama3"
    OPENAI_API_KEY=""
    ANTHROPIC_API_KEY=""
    GOOGLE_AI_API_KEY=""
    EMAIL_ENABLED="false"
    SMTP_SERVER=""
    SMTP_PORT="587"
    SMTP_USERNAME=""
    SMTP_PASSWORD=""
    SMTP_FROM_EMAIL=""
    ENABLE_REGISTRATION="true"
    GOOGLE_CLIENT_ID=""
    GOOGLE_CLIENT_SECRET=""
    GITHUB_CLIENT_ID=""
    GITHUB_CLIENT_SECRET=""
    POSTGRES_MAX_CONNECTIONS="100"
    POSTGRES_SHARED_BUFFERS="256MB"
    REDIS_MAXMEMORY="256mb"
    CELERY_CONCURRENCY="2"
    ENABLE_FLOWER="true"
    DEBUG_MODE="false"
fi

if [ "$DEBUG_MODE" = "true" ]; then
    LOG_LEVEL="DEBUG"
    UVICORN_LOG_LEVEL="debug"
    CELERY_LOG_LEVEL="debug"
    log "DEBUG MODE ENABLED - Verbose logging active"
else
    LOG_LEVEL="INFO"
    UVICORN_LOG_LEVEL="info"
    CELERY_LOG_LEVEL="info"
fi

# Get Home Assistant ingress information
INGRESS_PATH=""
if [ -n "$SUPERVISOR_TOKEN" ]; then
    log "Running as Home Assistant add-on with Supervisor..."
    ADDON_INFO=$(curl -s -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" http://supervisor/addons/self/info 2>/dev/null || echo "{}")
    INGRESS_ENTRY=$(echo "$ADDON_INFO" | jq -r '.data.ingress_entry // empty')
    if [ -n "$INGRESS_ENTRY" ]; then
        INGRESS_PATH="$INGRESS_ENTRY"
        log "Ingress path: $INGRESS_PATH"
    else
        log "Warning: Could not detect ingress path. Using direct access mode."
    fi
else
    log "Running in standalone mode (no SUPERVISOR_TOKEN)"
fi

# Export environment variables for the backend
export DATABASE_URL="postgresql://laro:laro@127.0.0.1:5432/laro"
export REDIS_URL="redis://127.0.0.1:6379"
export REDIS_PUBSUB_ENABLED="true"
export JWT_SECRET="$JWT_SECRET"
export LLM_PROVIDER="$LLM_PROVIDER"
export OLLAMA_URL="$OLLAMA_URL"
export OLLAMA_MODEL="$OLLAMA_MODEL"
export OPENAI_API_KEY="$OPENAI_API_KEY"
export ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY"
export GOOGLE_AI_API_KEY="$GOOGLE_AI_API_KEY"
export EMAIL_ENABLED="$EMAIL_ENABLED"
export SMTP_HOST="$SMTP_SERVER"
export SMTP_PORT="$SMTP_PORT"
export SMTP_USER="$SMTP_USERNAME"
export SMTP_PASSWORD="$SMTP_PASSWORD"
export SMTP_FROM_EMAIL="$SMTP_FROM_EMAIL"
export ENABLE_REGISTRATION="$ENABLE_REGISTRATION"
export GOOGLE_CLIENT_ID="$GOOGLE_CLIENT_ID"
export GOOGLE_CLIENT_SECRET="$GOOGLE_CLIENT_SECRET"
export GITHUB_CLIENT_ID="$GITHUB_CLIENT_ID"
export GITHUB_CLIENT_SECRET="$GITHUB_CLIENT_SECRET"
export CORS_ORIGINS="*"
export UPLOAD_DIR="/data/uploads"
export LARO_HA_ADDON="true"
export LARO_HA_ADDON="true"
export INGRESS_PATH="$INGRESS_PATH"
export DEBUG_MODE="$DEBUG_MODE"
export LOG_LEVEL="$LOG_LEVEL"
export UVICORN_LOG_LEVEL="$UVICORN_LOG_LEVEL"
export CELERY_LOG_LEVEL="$CELERY_LOG_LEVEL"
export CELERY_CONCURRENCY="$CELERY_CONCURRENCY"
export REDIS_MAXMEMORY="$REDIS_MAXMEMORY"
export ENABLE_FLOWER="$ENABLE_FLOWER"

# Ensure data directories exist with correct permissions
log "Setting up data directories..."
mkdir -p /data/postgres
mkdir -p /data/redis
mkdir -p /data/uploads
mkdir -p /var/log/laro
mkdir -p /var/run/postgresql

chmod 777 /var/log/laro

touch /var/log/laro/postgres.log /var/log/laro/postgres-error.log
chown postgres:postgres /var/log/laro/postgres.log /var/log/laro/postgres-error.log

chown -R postgres:postgres /data/postgres /var/run/postgresql
chown -R redis:redis /data/redis
chmod 700 /data/postgres

# Initialize PostgreSQL if not already initialized
if [ ! -d /data/postgres/base ]; then
    log "Initializing PostgreSQL database..."
    su - postgres -c "/usr/lib/postgresql/15/bin/initdb -D /data/postgres"

    cat >> /data/postgres/postgresql.conf <<EOF
max_connections = $POSTGRES_MAX_CONNECTIONS
shared_buffers = $POSTGRES_SHARED_BUFFERS
listen_addresses = '127.0.0.1'
port = 5432
unix_socket_directories = '/var/run/postgresql'
logging_collector = on
log_directory = '/var/log/laro'
log_filename = 'postgresql-%Y-%m-%d.log'
EOF

    su - postgres -c "/usr/lib/postgresql/15/bin/pg_ctl -D /data/postgres -l /var/log/laro/postgres.log start"
    sleep 5

    su - postgres -c "psql -c \"CREATE USER laro WITH PASSWORD 'laro';\""
    su - postgres -c "psql -c \"CREATE DATABASE laro OWNER laro;\""
    su - postgres -c "psql -c \"GRANT ALL PRIVILEGES ON DATABASE laro TO laro;\""

    su - postgres -c "/usr/lib/postgresql/15/bin/pg_ctl -D /data/postgres stop"

    log "PostgreSQL initialized successfully"
else
    log "PostgreSQL database already exists"
fi

# Update backend to use the data directory for uploads
if [ -L /app/backend/uploads ]; then
    rm /app/backend/uploads
fi
ln -sf /data/uploads /app/backend/uploads

# Update frontend base path for ingress if needed
if [ -n "$INGRESS_PATH" ]; then
    log "Configuring frontend for ingress path: $INGRESS_PATH"
    if [ -f /app/frontend/index.html ]; then
        if grep -q '<base href=' /app/frontend/index.html 2>/dev/null; then
            sed -i "s|<base href=\"[^\"]*\"|<base href=\"${INGRESS_PATH}/\"|g" /app/frontend/index.html
            log "Updated base href to: ${INGRESS_PATH}/"
        else
            sed -i "s|<head>|<head>\n    <base href=\"${INGRESS_PATH}/\" />|" /app/frontend/index.html
            log "Added base href: ${INGRESS_PATH}/"
        fi
    else
        log "Warning: /app/frontend/index.html not found"
    fi
else
    log "No ingress path configured, using default base href"
fi

# Honor Flower toggle in supervisord at runtime
if [ "$ENABLE_FLOWER" != "true" ]; then
    log "Flower dashboard disabled via options"
    if [ -f /etc/supervisor/conf.d/supervisord.conf ]; then
        sed -i '/\[program:flower\]/,/^\[/{s/^autostart=.*/autostart=false/}' /etc/supervisor/conf.d/supervisord.conf || true
    fi
fi

# Apply redis maxmemory / celery concurrency into supervisord command lines when possible
if [ -f /etc/supervisor/conf.d/supervisord.conf ]; then
    sed -i "s/--maxmemory [0-9]*[mMgG]b/--maxmemory ${REDIS_MAXMEMORY}/g" /etc/supervisor/conf.d/supervisord.conf || true
    sed -i "s/--concurrency=[0-9]*/--concurrency=${CELERY_CONCURRENCY}/g" /etc/supervisor/conf.d/supervisord.conf || true
fi

# Write environment file for supervisor processes
cat > /etc/laro.env << EOF
DATABASE_URL=$DATABASE_URL
REDIS_URL=$REDIS_URL
REDIS_PUBSUB_ENABLED=$REDIS_PUBSUB_ENABLED
JWT_SECRET=$JWT_SECRET
LLM_PROVIDER=$LLM_PROVIDER
OLLAMA_URL=$OLLAMA_URL
OLLAMA_MODEL=$OLLAMA_MODEL
OPENAI_API_KEY=$OPENAI_API_KEY
ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY
GOOGLE_AI_API_KEY=$GOOGLE_AI_API_KEY
EMAIL_ENABLED=$EMAIL_ENABLED
SMTP_HOST=$SMTP_HOST
SMTP_PORT=$SMTP_PORT
SMTP_USER=$SMTP_USER
SMTP_PASSWORD=$SMTP_PASSWORD
SMTP_FROM_EMAIL=$SMTP_FROM_EMAIL
ENABLE_REGISTRATION=$ENABLE_REGISTRATION
GOOGLE_CLIENT_ID=$GOOGLE_CLIENT_ID
GOOGLE_CLIENT_SECRET=$GOOGLE_CLIENT_SECRET
GITHUB_CLIENT_ID=$GITHUB_CLIENT_ID
GITHUB_CLIENT_SECRET=$GITHUB_CLIENT_SECRET
CORS_ORIGINS=$CORS_ORIGINS
UPLOAD_DIR=$UPLOAD_DIR
LARO_HA_ADDON=true
LARO_HA_ADDON=true
DEBUG_MODE=$DEBUG_MODE
LOG_LEVEL=$LOG_LEVEL
UVICORN_LOG_LEVEL=$UVICORN_LOG_LEVEL
CELERY_LOG_LEVEL=$CELERY_LOG_LEVEL
PATH=/opt/venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
EOF

log "Configuration complete. Starting services..."
log "  - PostgreSQL: 127.0.0.1:5432"
log "  - Redis: 127.0.0.1:6379"
log "  - Backend API: 127.0.0.1:8001"
log "  - Celery Worker: $CELERY_CONCURRENCY workers"
if [ "$ENABLE_FLOWER" = "true" ]; then
    log "  - Flower Dashboard: 127.0.0.1:5555"
fi
log "  - Frontend/Nginx: 0.0.0.0:3000"
log "  - LLM Provider: $LLM_PROVIDER"

if [ "$DEBUG_MODE" = "true" ]; then
    log "====== DEBUG INFO ======"
    log "Python version: $(python3 --version)"
    log "Environment variables written to: /etc/laro.env"
    log "Log files location: /var/log/laro/"
    log "======================="
fi

exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
