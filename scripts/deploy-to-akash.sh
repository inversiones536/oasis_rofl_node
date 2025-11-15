#!/bin/bash
# Automated Akash Deployment Script for Oasis ROFL Node

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

echo "🚀 Akash Deployment Script for Oasis ROFL Node"
echo "=============================================="
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if akash CLI is installed
if ! command -v akash &> /dev/null; then
    echo -e "${RED}Error: Akash CLI not found${NC}"
    echo "Install with: brew install akash"
    exit 1
fi

echo -e "${GREEN}✓ Akash CLI found${NC}"

# Setup environment
echo ""
echo "📋 Setting up Akash environment..."
export AKASH_NET="https://raw.githubusercontent.com/akash-network/net/main/mainnet"
export AKASH_CHAIN_ID="$(curl -s "$AKASH_NET/chain-id.txt")"
export AKASH_NODE="$(curl -s "$AKASH_NET/rpc-nodes.txt" | head -1)"
export AKASH_KEYRING_BACKEND=os

echo "   Chain ID: $AKASH_CHAIN_ID"
echo "   Node: $AKASH_NODE"
echo ""

# Prompt for wallet name
read -p "Enter your Akash wallet name (or press Enter for 'my-rofl-wallet'): " WALLET_NAME
WALLET_NAME=${WALLET_NAME:-my-rofl-wallet}
export AKASH_FROM=$WALLET_NAME

# Check if wallet exists
if ! akash keys show $AKASH_FROM &> /dev/null; then
    echo -e "${RED}Error: Wallet '$AKASH_FROM' not found${NC}"
    echo ""
    echo "Create a wallet first:"
    echo "  akash keys add $AKASH_FROM"
    echo ""
    echo "Or import existing:"
    echo "  akash keys add $AKASH_FROM --recover"
    exit 1
fi

export AKASH_ACCOUNT_ADDRESS=$(akash keys show $AKASH_FROM -a)
echo -e "${GREEN}✓ Using wallet: $AKASH_FROM${NC}"
echo "   Address: $AKASH_ACCOUNT_ADDRESS"
echo ""

# Check balance
echo "💰 Checking AKT balance..."
BALANCE=$(akash query bank balances $AKASH_ACCOUNT_ADDRESS --node $AKASH_NODE -o json | jq -r '.balances[] | select(.denom=="uakt") | .amount')
BALANCE_AKT=$(echo "scale=2; $BALANCE / 1000000" | bc)
echo "   Balance: $BALANCE_AKT AKT"

if (( $(echo "$BALANCE_AKT < 5" | bc -l) )); then
    echo -e "${YELLOW}⚠️  Warning: Balance is low. You need at least 5 AKT for deployment${NC}"
    read -p "Continue anyway? (y/n): " CONTINUE
    if [[ ! $CONTINUE =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi
echo ""

# Check/create certificate
echo "🔐 Checking deployment certificate..."
CERT_EXISTS=$(akash query cert list --owner $AKASH_ACCOUNT_ADDRESS --node $AKASH_NODE -o json | jq '.certificates | length')

if [ "$CERT_EXISTS" -eq "0" ]; then
    echo "   Creating certificate..."
    akash tx cert generate client \
      --from $AKASH_FROM \
      --chain-id $AKASH_CHAIN_ID \
      --node $AKASH_NODE \
      --gas-prices="0.025uakt" \
      --gas="auto" \
      --gas-adjustment=1.5 \
      --yes
    
    sleep 5
    
    echo "   Publishing certificate..."
    akash tx cert publish client \
      --from $AKASH_FROM \
      --chain-id $AKASH_CHAIN_ID \
      --node $AKASH_NODE \
      --gas-prices="0.025uakt" \
      --gas="auto" \
      --gas-adjustment=1.5 \
      --yes
    
    echo -e "${GREEN}✓ Certificate created and published${NC}"
else
    echo -e "${GREEN}✓ Certificate already exists${NC}"
fi
echo ""

# Create deployment
echo "🚀 Creating deployment..."
DEPLOY_OUTPUT=$(akash tx deployment create deploy.yaml \
  --from $AKASH_FROM \
  --chain-id $AKASH_CHAIN_ID \
  --node $AKASH_NODE \
  --gas-prices="0.025uakt" \
  --gas="auto" \
  --gas-adjustment=1.5 \
  --yes \
  -o json)

if [ $? -ne 0 ]; then
    echo -e "${RED}Error creating deployment${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Deployment transaction submitted${NC}"
echo "   Waiting for deployment to be created..."
sleep 10

# Get deployment sequence
AKASH_DSEQ=$(akash query deployment list --owner $AKASH_ACCOUNT_ADDRESS --node $AKASH_NODE -o json | jq -r '.deployments[0].deployment.deployment_id.dseq')

if [ -z "$AKASH_DSEQ" ] || [ "$AKASH_DSEQ" = "null" ]; then
    echo -e "${RED}Error: Could not get deployment sequence${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Deployment created${NC}"
echo "   DSEQ: $AKASH_DSEQ"
export AKASH_DSEQ
echo ""

# Wait for bids
echo "⏳ Waiting for provider bids (30 seconds)..."
sleep 30

# Query bids
echo "📊 Querying available bids..."
BIDS=$(akash query market bid list \
  --owner $AKASH_ACCOUNT_ADDRESS \
  --node $AKASH_NODE \
  --state open \
  -o json)

BID_COUNT=$(echo "$BIDS" | jq '.bids | length')

if [ "$BID_COUNT" -eq "0" ]; then
    echo -e "${RED}Error: No bids received${NC}"
    echo "Try closing and recreating the deployment:"
    echo "  akash tx deployment close --dseq $AKASH_DSEQ --from $AKASH_FROM --chain-id $AKASH_CHAIN_ID --node $AKASH_NODE"
    exit 1
fi

echo -e "${GREEN}✓ Received $BID_COUNT bid(s)${NC}"
echo ""

# Display bids
echo "Available providers:"
echo "$BIDS" | jq -r '.bids[] | "  Provider: \(.bid.bid_id.provider) | Price: \(.bid.price.amount)\(.bid.price.denom)/block"'
echo ""

# Auto-select cheapest provider
AKASH_PROVIDER=$(echo "$BIDS" | jq -r '[.bids[] | {provider: .bid.bid_id.provider, price: (.bid.price.amount | tonumber)}] | sort_by(.price) | .[0].provider')

echo -e "${GREEN}✓ Selected provider: $AKASH_PROVIDER${NC}"
export AKASH_PROVIDER
echo ""

# Create lease
echo "🤝 Creating lease with provider..."
akash tx market lease create \
  --dseq $AKASH_DSEQ \
  --provider $AKASH_PROVIDER \
  --from $AKASH_FROM \
  --chain-id $AKASH_CHAIN_ID \
  --node $AKASH_NODE \
  --gas-prices="0.025uakt" \
  --gas="auto" \
  --gas-adjustment=1.5 \
  --yes

echo -e "${GREEN}✓ Lease created${NC}"
echo "   Waiting for lease to be active..."
sleep 10
echo ""

# Send manifest
echo "📤 Sending deployment manifest to provider..."
akash provider send-manifest deploy.yaml \
  --dseq $AKASH_DSEQ \
  --provider $AKASH_PROVIDER \
  --from $AKASH_FROM \
  --home ~/.akash

if [ $? -ne 0 ]; then
    echo -e "${RED}Error sending manifest${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Manifest sent successfully${NC}"
echo ""

# Wait for deployment to start
echo "⏳ Waiting for deployment to start (30 seconds)..."
sleep 30

# Get deployment status
echo "📊 Checking deployment status..."
STATUS=$(akash provider lease-status \
  --dseq $AKASH_DSEQ \
  --provider $AKASH_PROVIDER \
  --from $AKASH_FROM \
  --home ~/.akash 2>/dev/null)

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Deployment is running!${NC}"
    echo ""
    echo "$STATUS"
else
    echo -e "${YELLOW}⚠️  Could not get status yet, deployment may still be starting${NC}"
fi

echo ""
echo "=============================================="
echo -e "${GREEN}🎉 Deployment Complete!${NC}"
echo "=============================================="
echo ""
echo "Deployment Information:"
echo "  DSEQ:     $AKASH_DSEQ"
echo "  Provider: $AKASH_PROVIDER"
echo "  Wallet:   $AKASH_FROM"
echo ""
echo "Useful Commands:"
echo ""
echo "  # Access shell:"
echo "  akash provider lease-shell --dseq $AKASH_DSEQ --provider $AKASH_PROVIDER --from $AKASH_FROM --home ~/.akash"
echo ""
echo "  # View logs:"
echo "  akash provider lease-logs --dseq $AKASH_DSEQ --provider $AKASH_PROVIDER --from $AKASH_FROM --home ~/.akash --follow"
echo ""
echo "  # Check status:"
echo "  akash provider lease-status --dseq $AKASH_DSEQ --provider $AKASH_PROVIDER --from $AKASH_FROM --home ~/.akash"
echo ""
echo "  # Close deployment:"
echo "  akash tx deployment close --dseq $AKASH_DSEQ --from $AKASH_FROM --chain-id $AKASH_CHAIN_ID --node $AKASH_NODE"
echo ""

# Save deployment info
cat > akash-deployment-info.txt << EOF
# Akash Deployment Information
# Generated: $(date)

AKASH_DSEQ=$AKASH_DSEQ
AKASH_PROVIDER=$AKASH_PROVIDER
AKASH_FROM=$AKASH_FROM
AKASH_ACCOUNT_ADDRESS=$AKASH_ACCOUNT_ADDRESS
AKASH_CHAIN_ID=$AKASH_CHAIN_ID
AKASH_NODE=$AKASH_NODE

# Quick Commands:
# Shell:  akash provider lease-shell --dseq $AKASH_DSEQ --provider $AKASH_PROVIDER --from $AKASH_FROM --home ~/.akash
# Logs:   akash provider lease-logs --dseq $AKASH_DSEQ --provider $AKASH_PROVIDER --from $AKASH_FROM --home ~/.akash --follow
# Status: akash provider lease-status --dseq $AKASH_DSEQ --provider $AKASH_PROVIDER --from $AKASH_FROM --home ~/.akash
# Close:  akash tx deployment close --dseq $AKASH_DSEQ --from $AKASH_FROM --chain-id $AKASH_CHAIN_ID --node $AKASH_NODE
EOF

echo -e "${GREEN}✓ Deployment info saved to: akash-deployment-info.txt${NC}"
echo ""
echo "To access your node, run:"
echo -e "${YELLOW}  ./scripts/akash-shell.sh${NC}"
echo ""
