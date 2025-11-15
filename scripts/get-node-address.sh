#!/bin/bash
# Get node address for funding

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
NODE_DIR="$PROJECT_ROOT/node"
BIN_DIR="$NODE_DIR/bin"

echo "==> Node Address for Funding"
echo ""

"$BIN_DIR/oasis-node" identity show-address -a "unix:$NODE_DIR/data/internal.sock"

echo ""
echo "Fund this address on Sapphire to cover ROFL registration and transaction fees."
echo "For testnet: https://faucet.testnet.oasis.io/?paratime=sapphire"
echo "For mainnet: Transfer tokens using: oasis account transfer <amount> <address>"
