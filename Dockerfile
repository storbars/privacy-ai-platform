# Backup Dockerfile - n8n only (uten Nillion for nå)
# Vi får Nillion til å fungere etter at n8n kjører

FROM node:18-bullseye

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    curl \
    wget \
    bash \
    openssl \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Set up working directory
WORKDIR /app

# Install n8n globally
RUN npm install -g n8n@latest

# Create n8n data directory
RUN mkdir -p /app/.n8n && \
    chmod 755 /app/.n8n

# Copy package.json first
COPY package*.json ./

# Install Node.js dependencies
RUN npm install

# Copy simplified startup script
COPY start-simple.sh /app/start.sh
RUN chmod +x /app/start.sh

# Environment variables
ENV N8N_USER_FOLDER=/app/.n8n
ENV N8N_BASIC_AUTH_ACTIVE=true
ENV N8N_BASIC_AUTH_USER=admin
ENV N8N_BASIC_AUTH_PASSWORD=changeme123
ENV N8N_HOST=0.0.0.0
ENV N8N_PORT=8080
ENV N8N_PROTOCOL=http

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=60s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8080/healthz || exit 1

# Start application
CMD ["/app/start.sh"]
