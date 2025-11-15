#!/bin/bash
# Start script for Oasis ROFL Node

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
NODE_DIR="$PROJECT_ROOT/node"
BIN_DIR="$NODE_DIR/bin"
ETC_DIR="$NODE_DIR/etc"
LOG_FILE="$NODE_DIR/data/node.log"

# Check if binaries exist
if [ ! -f "$BIN_DIR/oasis-node" ]; then
    echo "Error: oasis-node not found. Run ./scripts/setup.sh first."
    exit 1
fi

if [ ! -f "$ETC_DIR/config.yml" ]; then
    echo "Error: config.yml not found in $ETC_DIR"
    exit 1
fi

echo "==> Starting Oasis ROFL Node..."
echo "    Config: $ETC_DIR/config.yml"
echo "    Logs: $LOG_FILE"
echo ""

# Start the node
exec "$BIN_DIR/oasis-node" --config "$ETC_DIR/config.yml" 2>&1 | tee "$LOG_FILE"
