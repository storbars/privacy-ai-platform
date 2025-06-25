# N8N with Nillion SDK - Proper isolation approach
FROM n8nio/n8n:latest

# Switch to root for installations
USER root

# Install system dependencies for Nillion
RUN apk add --no-cache git make g++ python3

# Install Nillion SDK globally WITHOUT touching n8n's internals
RUN npm install -g @nillion/client-core@latest @nillion/client-vms@latest

# Verify n8n command still exists and works
RUN which n8n && n8n --version

# Set Nillion environment variables
ENV NILLION_NETWORK=mainnet
ENV NILLION_RPC_URL=https://nilchain-rpc.nillion.network
ENV NILLION_API_URL=https://nilchain-api.nillion.network
ENV NILLION_GRPC_URL=https://nillion-grpc.lavenderfive.com

# N8N configuration
ENV N8N_HOST=0.0.0.0
ENV N8N_PORT=5678
ENV N8N_PROTOCOL=https
ENV N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true
ENV NODE_OPTIONS="--max-old-space-size=2048"

# Make sure node user can access everything
RUN chown -R node:node /home/node

# Switch back to node user
USER node

# Set working directory
WORKDIR /home/node

# Expose port
EXPOSE 5678

# Use the EXACT same startup as original n8n image
ENTRYPOINT ["tini", "--", "/docker-entrypoint.sh"]
CMD ["n8n"]
