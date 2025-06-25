# Privacy-First AI Platform - N8N with Nillion SDK
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

# Create directory for custom packages
WORKDIR /tmp/nillion-setup

# Copy package.json for Nillion dependencies
COPY package.json ./

# Install Nillion SDK packages globally
RUN npm install -g @nillion/client-wasm@latest @nillion/client-vms@latest

# Alternative: Install locally for n8n (uncomment if global doesn't work)
# RUN cd /usr/local/lib/node_modules/n8n && \
#     npm install @nillion/client-wasm@latest @nillion/client-vms@latest

# Set Nillion environment variables
ENV NILLION_NETWORK=mainnet
ENV NILLION_RPC_URL=https://nilchain-rpc.nillion.network
ENV NILLION_API_URL=https://nilchain-api.nillion.network
ENV NILLION_GRPC_URL=https://nillion-grpc.lavenderfive.com

# Set Node.js memory options for larger workflows
ENV NODE_OPTIONS="--max-old-space-size=2048"

# Create logs directory for privacy layer
RUN mkdir -p /home/node/.n8n/logs && \
    chown -R node:node /home/node/.n8n/logs

# Switch back to node user for security
USER node

# Set working directory back to n8n default
WORKDIR /home/node

# Expose n8n default port
EXPOSE 5678

# Health check to ensure n8n is running
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:5678/healthz || exit 1

# Start n8n with privacy-first configuration
CMD ["n8n", "start"]
