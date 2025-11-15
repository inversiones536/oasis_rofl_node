#!/bin/bash
# Check node status

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
NODE_DIR="$PROJECT_ROOT/node"
BIN_DIR="$NODE_DIR/bin"

echo "==> Checking Oasis Node Status"
echo ""

"$BIN_DIR/oasis-node" control status -a "unix:$NODE_DIR/data/internal.sock"
