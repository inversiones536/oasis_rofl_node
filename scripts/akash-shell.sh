#!/bin/bash
# Quick access to Akash deployment shell

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Load deployment info
if [ ! -f "$PROJECT_ROOT/akash-deployment-info.txt" ]; then
    echo "Error: No deployment info found"
    echo "Run ./scripts/deploy-to-akash.sh first"
    exit 1
fi

source "$PROJECT_ROOT/akash-deployment-info.txt"

echo "Connecting to Akash deployment..."
echo "DSEQ: $AKASH_DSEQ"
echo "Provider: $AKASH_PROVIDER"
echo ""

akash provider lease-shell \
  --dseq $AKASH_DSEQ \
  --provider $AKASH_PROVIDER \
  --from $AKASH_FROM \
  --home ~/.akash
