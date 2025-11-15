#!/bin/bash
# Build ROFL app from source with debug/mock SGX flags

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ROFL_DIR="$PROJECT_ROOT/node/rofls"
BUILD_DIR="$PROJECT_ROOT/rofl-build"

echo "==> Building ROFL app with mock SGX support..."

# Install build dependencies
echo "==> Installing build dependencies..."
apt-get update -qq
apt-get install -y -qq build-essential pkg-config libssl-dev > /dev/null 2>&1
echo "    ✓ Build tools installed"

# Install Rust if not present
if ! command -v cargo &> /dev/null; then
    echo "==> Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
fi

# Install fortanix target for SGX (but we'll use mock mode)
rustup target add x86_64-fortanix-unknown-sgx

# Clone the Oasis SDK (contains example ROFL apps)
echo "==> Cloning Oasis SDK..."
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

if [ ! -d "oasis-sdk" ]; then
    git clone https://github.com/oasisprotocol/oasis-sdk.git
fi

cd oasis-sdk

# Build the test ROFL app with mock SGX feature
echo "==> Building test ROFL app with debug-mock-sgx feature..."
cd tests/runtimes/components-rofl

# Enable mock SGX feature
cargo build --release --features debug-mock-sgx --target x86_64-fortanix-unknown-sgx

echo "==> Converting SGX binary to ORC bundle..."
BINARY_PATH="target/x86_64-fortanix-unknown-sgx/release/test-runtime-components-rofl"

if [ ! -f "$BINARY_PATH" ]; then
    echo "Error: Binary not found at $BINARY_PATH"
    exit 1
fi

# Create ORC bundle (just a tar.gz with metadata)
mkdir -p "$ROFL_DIR"
cd "$BUILD_DIR/oasis-sdk/tests/runtimes/components-rofl"

# Create ORC structure
ORC_TMP="$BUILD_DIR/orc-tmp"
rm -rf "$ORC_TMP"
mkdir -p "$ORC_TMP"

cp "$BINARY_PATH" "$ORC_TMP/rofl-app"
chmod +x "$ORC_TMP/rofl-app"

# Create manifest
cat > "$ORC_TMP/manifest.json" <<EOF
{
  "name": "test-rofl-app",
  "version": "0.1.0",
  "id": "$(echo -n 'test-rofl' | sha256sum | cut -d' ' -f1)",
  "kind": "ronl",
  "sgx": {
    "executable": "rofl-app"
  }
}
EOF

# Package into ORC
cd "$ORC_TMP"
tar czf "$ROFL_DIR/rofl-app.orc" .

echo "==> ROFL app built successfully!"
echo "    Location: $ROFL_DIR/rofl-app.orc"
echo "    Features: debug-mock-sgx (no real SGX required)"
