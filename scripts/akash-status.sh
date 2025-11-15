#!/bin/bash
# Check Akash deployment status

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Load deployment info
if [ ! -f "$PROJECT_ROOT/akash-deployment-info.txt" ]; then
    echo "Error: No deployment info found"
    echo "Run ./scripts/deploy-to-akash.sh first"
    exit 1
fi

source "$PROJECT_ROOT/akash-deployment-info.txt"

echo "Checking Akash deployment status..."
echo ""

akash provider lease-status \
  --dseq $AKASH_DSEQ \
  --provider $AKASH_PROVIDER \
  --from $AKASH_FROM \
  --home ~/.akash
