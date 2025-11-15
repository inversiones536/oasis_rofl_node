#!/bin/bash
# Close Akash deployment and get refund

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Load deployment info
if [ ! -f "$PROJECT_ROOT/akash-deployment-info.txt" ]; then
    echo "Error: No deployment info found"
    echo "Run ./scripts/deploy-to-akash.sh first"
    exit 1
fi

source "$PROJECT_ROOT/akash-deployment-info.txt"

echo "⚠️  WARNING: This will close your deployment and stop the node!"
echo ""
echo "DSEQ: $AKASH_DSEQ"
echo "Provider: $AKASH_PROVIDER"
echo ""
read -p "Are you sure you want to close this deployment? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Cancelled"
    exit 0
fi

echo ""
echo "Closing deployment..."

akash tx deployment close \
  --dseq $AKASH_DSEQ \
  --from $AKASH_FROM \
  --chain-id $AKASH_CHAIN_ID \
  --node $AKASH_NODE \
  --gas-prices="0.025uakt" \
  --gas="auto" \
  --gas-adjustment=1.5 \
  --yes

echo ""
echo "✓ Deployment closed"
echo "Your remaining funds will be returned to your account"
