FROM ubuntu:22.04

# Avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && \
    apt-get install -y \
    curl \
    jq \
    git \
    ca-certificates \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Create application directory
WORKDIR /app

# Copy all project files
COPY . .

# Make scripts executable
RUN chmod +x scripts/*.sh

# Run setup script
ARG NETWORK=testnet
ENV NETWORK=${NETWORK}
RUN ./scripts/setup.sh

# Create non-root user for security
RUN useradd -r -m -s /bin/bash oasis && \
    chown -R oasis:oasis /app

# Expose ports
EXPOSE 26656 9200

# Switch to non-root user
USER oasis

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
  CMD node/bin/oasis-node control status -a unix:/app/node/data/internal.sock || exit 1

# Start node
CMD ["./scripts/start-node.sh"]
