#!/bin/bash
# start-simple.sh - Simplified startup script (uten Nillion for nå)

set -e

echo "🚀 Starting n8n on Railway..."

# Railway environment variables setup
export N8N_HOST=${N8N_HOST:-"0.0.0.0"}
export N8N_PORT=${PORT:-8080}
export N8N_PROTOCOL=${N8N_PROTOCOL:-"http"}

# n8n environment variables
export N8N_USER_FOLDER="/app/.n8n"
export N8N_ENCRYPTION_KEY=${N8N_ENCRYPTION_KEY:-$(openssl rand -hex 32)}

echo "📋 Configuration:"
echo "   Host: $N8N_HOST"
echo "   Port: $N8N_PORT"
echo "   User folder: $N8N_USER_FOLDER"

# Webhook URL setup for Railway
if [ -n "$RAILWAY_STATIC_URL" ]; then
    export WEBHOOK_URL="https://$RAILWAY_STATIC_URL"
    echo "   Webhook URL: $WEBHOOK_URL"
fi

# Start n8n
echo "🎯 Starting n8n..."

# Cleanup function ved shutdown
cleanup() {
    echo "🛑 Shutting down gracefully..."
    exit 0
}

# Trap signals for graceful shutdown
trap cleanup SIGTERM SIGINT

# Start n8n
exec n8n start
