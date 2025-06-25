#!/bin/bash
# start.sh - Startup script for n8n + Nillion på Railway

set -e

echo "🚀 Starting Privacy-First AI Platform på Railway..."

# Sett opp Nillion environment
export PATH="/usr/local/bin:$PATH"

# Sjekk at Nillion binaries er tilgjengelige
echo "🔧 Checking Nillion installation..."
if command -v nillion &> /dev/null; then
    echo "✅ Nillion CLI found: $(nillion --version)"
else
    echo "❌ Nillion CLI not found!"
    exit 1
fi

# Railway environment variables setup
export N8N_HOST=${N8N_HOST:-"0.0.0.0"}
export N8N_PORT=${PORT:-8080}  # Railway setter PORT automatisk
export N8N_PROTOCOL=${N8N_PROTOCOL:-"http"}

# Sett opp Nillion network config (Default: lokal devnet - ingen nøkler påkrevd!)
DEVNET_MODE=${NILLION_DEVNET_MODE:-"local"}

if [ "$DEVNET_MODE" = "local" ]; then
    echo "🌐 Starting local Nillion devnet (gratis, ingen API nøkler påkrevd)..."
    
    # Start devnet i bakgrunnen med fixed seed for konsistens
    nillion-devnet --seed "railway-privacy-platform-seed" &
    DEVNET_PID=$!
    echo "Started devnet with PID: $DEVNET_PID"
    
    # Vent for at devnet skal være klar
    echo "⏳ Waiting for devnet to initialize..."
    sleep 15
    
    # Eksporter devnet config fra environment file
    DEVNET_ENV_FILE="/root/.config/nillion/nillion-devnet.env"
    if [ -f "$DEVNET_ENV_FILE" ]; then
        echo "📋 Loading devnet configuration..."
        source "$DEVNET_ENV_FILE"
        
        # Eksporter viktige variabler
        export NILLION_CLUSTER_ID="$NILLION_CLUSTER_ID"
        export NILLION_JSON_RPC="$NILLION_NILCHAIN_JSON_RPC"
        export NILLION_WEBSOCKET="$NILLION_BOOTNODE_WEBSOCKET"
        export NILLION_PRIVATE_KEY="$NILLION_NILCHAIN_PRIVATE_KEY_0"  # Forhåndsfinansiert
        
        echo "✅ Devnet ready!"
        echo "   Cluster ID: $NILLION_CLUSTER_ID"
        echo "   JSON RPC: $NILLION_JSON_RPC"
        echo "   Using pre-funded private key for operations"
    else
        echo "❌ Devnet config file not found!"
        exit 1
    fi
    
elif [ "$DEVNET_MODE" = "testnet" ]; then
    echo "🌍 Using Nillion testnet..."
    # For testnet trengs det NIL tokens fra faucet
    export NILLION_JSON_RPC="http://rpc.testnet.nilchain-rpc-proxy.nilogy.xyz"
    export NILLION_CLUSTER_ID=${NILLION_TESTNET_CLUSTER_ID}
    export NILLION_PRIVATE_KEY=${NILLION_TESTNET_PRIVATE_KEY}
    
    if [ -z "$NILLION_PRIVATE_KEY" ]; then
        echo "❌ NILLION_TESTNET_PRIVATE_KEY required for testnet mode"
        echo "💡 Get NIL tokens from: https://faucet.testnet.nillion.com/"
        exit 1
    fi
    
else
    echo "❌ Invalid NILLION_DEVNET_MODE: $DEVNET_MODE"
    echo "💡 Valid modes: 'local' (default, gratis) eller 'testnet'"
    exit 1
fi

# Generer user keys hvis de ikke eksisterer
if [ ! -f "/app/.n8n/nillion-user.key" ]; then
    echo "🔑 Generating Nillion user keys..."
    nillion --user-key generate > /app/.n8n/nillion-user.key
    echo "✅ User keys generated"
fi

# Last inn user key
export NILLION_USER_KEY=$(cat /app/.n8n/nillion-user.key)

# Sett opp n8n environment variables
export N8N_USER_FOLDER="/app/.n8n"
export N8N_ENCRYPTION_KEY=${N8N_ENCRYPTION_KEY:-$(openssl rand -hex 32)}

# Database URL for Railway PostgreSQL (hvis tilgjengelig)
if [ -n "$DATABASE_URL" ]; then
    echo "🗄️  Using Railway PostgreSQL database"
    export DB_TYPE="postgresdb"
    export DB_POSTGRESDB_DATABASE=$(echo $DATABASE_URL | sed -n 's/.*\/\([^?]*\).*/\1/p')
    export DB_POSTGRESDB_HOST=$(echo $DATABASE_URL | sed -n 's/.*@\([^:]*\):.*/\1/p')
    export DB_POSTGRESDB_PORT=$(echo $DATABASE_URL | sed -n 's/.*:\([0-9]*\)\/.*/\1/p')
    export DB_POSTGRESDB_USER=$(echo $DATABASE_URL | sed -n 's/.*\/\/\([^:]*\):.*/\1/p')
    export DB_POSTGRESDB_PASSWORD=$(echo $DATABASE_URL | sed -n 's/.*\/\/[^:]*:\([^@]*\)@.*/\1/p')
    export DB_POSTGRESDB_SSL_ENABLED=true
else
    echo "📁 Using SQLite database (file-based)"
fi

# Webhook URL setup for Railway
if [ -n "$RAILWAY_STATIC_URL" ]; then
    export WEBHOOK_URL="https://$RAILWAY_STATIC_URL"
    echo "🌐 Webhook URL set to: $WEBHOOK_URL"
fi

# Start n8n
echo "🎯 Starting n8n..."
echo "   Host: $N8N_HOST"
echo "   Port: $N8N_PORT"
echo "   Webhook URL: $WEBHOOK_URL"
echo "   Nillion JSON RPC: $NILLION_JSON_RPC"

# Cleanup function ved shutdown
cleanup() {
    echo "🛑 Shutting down gracefully..."
    if [ -n "$DEVNET_PID" ]; then
        echo "Stopping local devnet..."
        kill $DEVNET_PID 2>/dev/null || true
    fi
    exit 0
}

# Trap signals for graceful shutdown
trap cleanup SIGTERM SIGINT

# Start n8n (dette blokker til prosessen avsluttes)
exec n8n start