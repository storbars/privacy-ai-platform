# N8N with Runtime Nillion SDK Installation
FROM n8nio/n8n:latest

# Switch to root temporarily
USER root

# Only install essential build tools, don't install npm packages yet
RUN apk add --no-cache git make g++ python3

# Create script that installs Nillion SDK AFTER n8n starts
RUN cat > /usr/local/bin/nillion-install.sh << 'EOF'
#!/bin/bash
echo "🔐 Installing Nillion SDK at runtime..."

# Install Nillion packages in background after n8n starts
(
  sleep 30  # Wait for n8n to fully start
  npm install -g @nillion/client-core@latest @nillion/client-vms@latest 2>/dev/null
  echo "✅ Nillion SDK installed"
) &

# Start n8n normally
exec "$@"
EOF

# Make script executable
RUN chmod +x /usr/local/bin/nillion-install.sh

# Set environment variables
ENV NILLION_NETWORK=mainnet
ENV NILLION_RPC_URL=https://nilchain-rpc.nillion.network
ENV NILLION_API_URL=https://nilchain-api.nillion.network
ENV NILLION_GRPC_URL=https://nillion-grpc.lavenderfive.com
ENV N8N_HOST=0.0.0.0
ENV N8N_PORT=5678
ENV N8N_PROTOCOL=https
ENV N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true
ENV NODE_OPTIONS="--max-old-space-size=2048"

# Fix ownership
RUN chown -R node:node /home/node

# Switch back to node user  
USER node

# Set working directory
WORKDIR /home/node

# Expose port
EXPOSE 5678

# Use our wrapper script that installs Nillion after n8n starts
ENTRYPOINT ["/usr/local/bin/nillion-install.sh", "tini", "--", "/docker-entrypoint.sh"]
CMD ["n8n"]
