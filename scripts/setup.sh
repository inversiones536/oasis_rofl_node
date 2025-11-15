#!/bin/bash
# Setup script for Oasis ROFL Node
# This script downloads necessary binaries and prepares the environment

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
NODE_DIR="$PROJECT_ROOT/node"
BIN_DIR="$NODE_DIR/bin"
ETC_DIR="$NODE_DIR/etc"
ROFLS_DIR="$NODE_DIR/rofls"

# Configuration
NETWORK="${NETWORK:-testnet}"  # testnet or mainnet
OASIS_NODE_VERSION="${OASIS_NODE_VERSION:-24.2}"  # Update to latest version
OASIS_CORE_RUNTIME_LOADER_VERSION="${OASIS_CORE_RUNTIME_LOADER_VERSION:-24.2}"
OASIS_CLI_VERSION="${OASIS_CLI_VERSION:-0.10.0}"

echo "==> Setting up Oasis ROFL Node"
echo "    Network: $NETWORK"
echo "    Project root: $PROJECT_ROOT"
echo ""

# Detect OS and architecture
OS="$(uname -s)"
ARCH="$(uname -m)"

case "$OS" in
    Linux*)
        OS_NAME="linux"
        ;;
    Darwin*)
        OS_NAME="darwin"
        ;;
    *)
        echo "Unsupported OS: $OS"
        exit 1
        ;;
esac

case "$ARCH" in
    x86_64|amd64)
        ARCH_NAME="amd64"
        ;;
    aarch64|arm64)
        ARCH_NAME="arm64"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

echo "==> Detected platform: $OS_NAME/$ARCH_NAME"
echo ""

# Download oasis-node
echo "==> Downloading oasis-node v$OASIS_NODE_VERSION..."
OASIS_NODE_URL="https://github.com/oasisprotocol/oasis-core/releases/download/v${OASIS_NODE_VERSION}/oasis_core_${OASIS_NODE_VERSION}_${OS_NAME}_${ARCH_NAME}.tar.gz"
curl -L "$OASIS_NODE_URL" -o /tmp/oasis-node.tar.gz
tar -xzf /tmp/oasis-node.tar.gz -C "$BIN_DIR" oasis-node
chmod +x "$BIN_DIR/oasis-node"
rm /tmp/oasis-node.tar.gz
echo "    ✓ oasis-node installed to $BIN_DIR/oasis-node"

# Download oasis-core-runtime-loader
echo "==> Downloading oasis-core-runtime-loader v$OASIS_CORE_RUNTIME_LOADER_VERSION..."
LOADER_URL="https://github.com/oasisprotocol/oasis-core/releases/download/v${OASIS_CORE_RUNTIME_LOADER_VERSION}/oasis_core_${OASIS_CORE_RUNTIME_LOADER_VERSION}_${OS_NAME}_${ARCH_NAME}.tar.gz"
curl -L "$LOADER_URL" -o /tmp/loader.tar.gz
tar -xzf /tmp/loader.tar.gz -C "$BIN_DIR" oasis-core-runtime-loader
chmod +x "$BIN_DIR/oasis-core-runtime-loader"
rm /tmp/loader.tar.gz
echo "    ✓ oasis-core-runtime-loader installed to $BIN_DIR/oasis-core-runtime-loader"

# Download Oasis CLI
echo "==> Downloading Oasis CLI v$OASIS_CLI_VERSION..."
CLI_URL="https://github.com/oasisprotocol/cli/releases/download/v${OASIS_CLI_VERSION}/oasis_cli_${OASIS_CLI_VERSION}_${OS_NAME}_${ARCH_NAME}.tar.gz"
curl -L "$CLI_URL" -o /tmp/oasis-cli.tar.gz
tar -xzf /tmp/oasis-cli.tar.gz -C "$BIN_DIR" oasis
chmod +x "$BIN_DIR/oasis"
rm /tmp/oasis-cli.tar.gz
echo "    ✓ Oasis CLI installed to $BIN_DIR/oasis"

# Download genesis file
echo "==> Downloading genesis file for $NETWORK..."
if [ "$NETWORK" = "mainnet" ]; then
    GENESIS_URL="https://github.com/oasisprotocol/mainnet-artifacts/releases/latest/download/genesis.json"
else
    GENESIS_URL="https://github.com/oasisprotocol/testnet-artifacts/releases/latest/download/genesis.json"
fi
curl -L "$GENESIS_URL" -o "$ETC_DIR/genesis.json"
echo "    ✓ Genesis file downloaded to $ETC_DIR/genesis.json"

# Download ROFL Scheduler app
echo "==> Downloading ROFL Scheduler app for $NETWORK..."
SCHEDULER_URL="https://github.com/oasisprotocol/oasis-sdk/releases/latest/download/rofl-scheduler.${NETWORK}.orc"
curl -L "$SCHEDULER_URL" -o "$ROFLS_DIR/rofl-scheduler.${NETWORK}.orc"
echo "    ✓ ROFL Scheduler downloaded to $ROFLS_DIR/rofl-scheduler.${NETWORK}.orc"

# Create identity if it doesn't exist
if [ ! -f "$NODE_DIR/data/identity.pem" ]; then
    echo "==> Generating node identity..."
    "$BIN_DIR/oasis-node" identity init --datadir "$NODE_DIR/data"
    echo "    ✓ Node identity created"
else
    echo "==> Node identity already exists"
fi

# Display node ID
echo ""
echo "==> Node Identity Information:"
"$BIN_DIR/oasis-node" identity show-id --datadir "$NODE_DIR/data"

echo ""
echo "==> Setup complete!"
echo ""
echo "Next steps:"
echo "1. Review and update $ETC_DIR/config.yml"
echo "2. Add seed node addresses to config.yml"
echo "3. Review and update $PROJECT_ROOT/rofl-provider.yaml"
echo "4. Configure firewall (optional): sudo ./scripts/configure-firewall.sh"
echo "5. Initialize node account: $BIN_DIR/oasis account create"
echo "6. Fund your node account on Sapphire"
echo "7. Register as ROFL provider: $BIN_DIR/oasis rofl provider create"
echo "8. Start the node: ./scripts/start-node.sh"
echo ""
