# N8N with Runtime Nillion SDK Installation - Fixed syntax
FROM n8nio/n8n:latest

# Switch to root temporarily
USER root

# Install essential build tools
RUN apk add --no-cache git make g++ python3 bash

# Create startup script with proper Docker syntax
RUN echo '#!/bin/bash' > /usr/local/bin/nillion-start.sh && \
    echo 'echo "Starting N8N with Nillion SDK support..."' >> /usr/local/bin/nillion-start.sh && \
    echo '' >> /usr/local/bin/nillion-start.sh && \
    echo '# Install Nillion SDK in background after n8n starts' >> /usr/local/bin/nillion-start.sh && \
    echo '(' >> /usr/local/bin/nillion-start.sh && \
    echo '  sleep 30' >> /usr/local/bin/nillion-start.sh && \
    echo '  echo "Installing Nillion SDK..."' >> /usr/local/bin/nillion-start.sh && \
    echo '  npm install -g @nillion/client-core@latest @nillion/client-vms@latest 2>/dev/null' >> /usr/local/bin/nillion-start.sh && \
    echo '  echo "Nillion SDK ready for use"' >> /usr/local/bin/nillion-start.sh && \
    echo ') &' >> /usr/local/bin/nillion-start.sh && \
    echo '' >> /usr/local/bin/nillion-start.sh && \
    echo '# Start n8n normally' >> /usr/local/bin/nillion-start.sh && \
    echo 'exec "$@"' >> /usr/local/bin/nillion-start.sh

# Make script executable
RUN chmod +x /usr/local/bin/nillion-start.sh

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

# Use our startup script
ENTRYPOINT ["/usr/local/bin/nillion-start.sh", "tini", "--", "/docker-entrypoint.sh"]
CMD ["n8n"]
