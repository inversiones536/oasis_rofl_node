#!/bin/bash
# Run ROFL scheduler application

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
NODE_DIR="$PROJECT_ROOT/node"
ROFL_DIR="$NODE_DIR/rofls"
DATA_DIR="$NODE_DIR/data"

echo "==> Extracting ROFL scheduler app..."

# Extract the ROFL app from the ORC bundle
cd "$ROFL_DIR"
if [ ! -f "rofl-scheduler.testnet.orc" ]; then
    echo "Error: ROFL scheduler ORC bundle not found"
    exit 1
fi

# ORC is just a tar.gz file
tar -xzf rofl-scheduler.testnet.orc

# Find the executable
ROFL_BINARY=$(find . -type f -name "rofl-scheduler" -o -name "rofl*" | head -n 1)

if [ -z "$ROFL_BINARY" ]; then
    echo "Error: Could not find ROFL scheduler binary in ORC bundle"
    echo "Contents:"
    ls -la
    exit 1
fi

chmod +x "$ROFL_BINARY"

echo "==> Found ROFL binary: $ROFL_BINARY"
echo "==> Starting ROFL scheduler app..."

# Set required environment variables
export OASIS_NODE_SOCKET="unix:$NODE_DIR/internal.sock"
export OASIS_WORKER_HOST="unix:$NODE_DIR/worker.sock"  
export ROFL_APP_ID=$(basename "$ROFL_DIR" .orc | cut -d'.' -f2-)

# Run the ROFL app
exec "$ROFL_BINARY"
