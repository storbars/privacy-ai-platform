# Privacy-First AI Platform - N8N with Nillion SDK
# Using separate installation approach to avoid workspace conflicts
FROM n8nio/n8n:latest

# Switch to root to install additional packages
USER root

# Install system dependencies needed for Nillion SDK
RUN apk add --no-cache \
    git \
    python3 \
    py3-pip \
    make \
    g++ \
    libc6-compat \
    curl

# Set environment variables
ENV NILLION_NETWORK=mainnet
ENV NILLION_RPC_URL=https://nilchain-rpc.nillion.network
ENV NILLION_API_URL=https://nilchain-api.nillion.network
ENV NILLION_GRPC_URL=https://nillion-grpc.lavenderfive.com
ENV N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true
ENV NODE_OPTIONS="--max-old-space-size=2048"

# Create separate directory for Nillion packages
RUN mkdir -p /opt/nillion && cd /opt/nillion

# Initialize a fresh package.json for Nillion
RUN cd /opt/nillion && npm init -y

# Install Nillion packages in separate directory
RUN cd /opt/nillion && \
    npm install @nillion/client-wasm@0.6.0 @nillion/client-vms@0.6.0

# Add Nillion modules to Node.js path so n8n can find them
ENV NODE_PATH="/opt/nillion/node_modules:$NODE_PATH"

# Create custom node_modules symlinks so n8n can require() them
RUN mkdir -p /home/node/nillion-modules && \
    ln -s /opt/nillion/node_modules/@nillion /home/node/nillion-modules/@nillion

# Add to require path for n8n Function nodes
ENV N8N_CUSTOM_EXTENSIONS="/home/node/nillion-modules"

# Fix ownership and permissions
RUN chown -R node:node /home/node && \
    chown -R node:node /opt/nillion

# Switch back to node user
USER node

# Set working directory
WORKDIR /home/node

# Expose n8n default port
EXPOSE 5678

# Use original n8n entrypoint
ENTRYPOINT ["tini", "--", "/docker-entrypoint.sh"]
CMD ["n8n"]
