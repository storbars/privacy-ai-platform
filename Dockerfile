# Fixed Dockerfile for n8n + Nillion på Railway
FROM ubuntu:22.04 AS nillion-builder

# Prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Install ALL necessary dependencies first
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    bash \
    build-essential \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /tmp

# Download and install Nillion SDK with better error handling
RUN echo "Downloading Nillion installer..." && \
    curl -L -o install.sh https://github.com/NillionNetwork/nillion-sdk/releases/latest/download/install.sh && \
    echo "Making installer executable..." && \
    chmod +x install.sh && \
    echo "Running Nillion installer..." && \
    bash install.sh && \
    echo "Nillion installation completed"

# Verify installation and copy binaries
RUN echo "Verifying Nillion installation..." && \
    ls -la /root/.local/bin/ && \
    /root/.local/bin/nilup --version && \
    /root/.local/bin/nillion --version

# Copy Nillion binaries to a clean location
RUN mkdir -p /nillion-dist/bin && \
    cp /root/.local/bin/* /nillion-dist/bin/ && \
    echo "Nillion binaries copied successfully"

# Main application stage - using Node.js base for better compatibility
FROM node:18-bullseye AS final

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    build-essential \
    curl \
    bash \
    openssl \
    && rm -rf /var/lib/apt/lists/*

# Copy Nillion binaries from builder stage
COPY --from=nillion-builder /nillion-dist/bin/* /usr/local/bin/

# Verify Nillion binaries are accessible
RUN echo "Verifying Nillion in final stage..." && \
    ls -la /usr/local/bin/ && \
    nillion --version || echo "Nillion binary check failed, but continuing..."

# Set up working directory
WORKDIR /app

# Install n8n globally
RUN npm install -g n8n@latest

# Create n8n data directory with proper permissions
RUN mkdir -p /app/.n8n && \
    chmod 755 /app/.n8n

# Copy package.json first for better Docker layer caching
COPY package*.json ./

# Install Node.js dependencies
RUN npm install

# Copy startup script and make it executable
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

# Environment variables
ENV N8N_USER_FOLDER=/app/.n8n
ENV N8N_BASIC_AUTH_ACTIVE=true
ENV N8N_BASIC_AUTH_USER=admin
ENV N8N_BASIC_AUTH_PASSWORD=changeme123
ENV N8N_HOST=0.0.0.0
ENV N8N_PORT=8080
ENV N8N_PROTOCOL=http
ENV NILLION_DEVNET_MODE=local
ENV PATH="/usr/local/bin:${PATH}"

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=60s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8080/healthz || exit 1

# Start application
CMD ["/app/start.sh"]
