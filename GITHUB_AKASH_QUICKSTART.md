# GitHub + Akash Quick Start

## 📤 Push to GitHub

### 1. Initialize Git Repository
```bash
cd "/Volumes/Samsung USB/crypto/rofl-node"

# Initialize repo
git init

# Add all files
git add .

# Initial commit
git commit -m "Initial Oasis ROFL node setup"
```

### 2. Create GitHub Repository
1. Go to https://github.com/new
2. Create a new repository (e.g., `oasis-rofl-node`)
3. **Do NOT** initialize with README (you already have one)
4. Choose **Public** or **Private** (Private recommended for production)

### 3. Push to GitHub
```bash
# Add remote (replace with your repo URL)
git remote add origin https://github.com/YOUR_USERNAME/oasis-rofl-node.git

# Push to main branch
git branch -M main
git push -u origin main
```

### ⚠️ Security Check Before Pushing

Verify no secrets are included:
```bash
# Check what will be committed
git status

# Verify .gitignore is working
git ls-files | grep -E '\.pem$|\.key$|identity'

# Should return nothing - if it shows files, they're NOT ignored!
```

## 🚀 Deploy on Akash

### Prerequisites
```bash
# Install Akash CLI
# macOS
brew install akash

# Linux
curl -sSfL https://raw.githubusercontent.com/akash-network/node/master/install.sh | sh

# Verify installation
akash version
```

### 1. Setup Akash Wallet
```bash
# Create or import wallet
akash keys add my-rofl-wallet
# or
akash keys add my-rofl-wallet --recover

# Fund wallet with AKT tokens
# Buy from exchange and withdraw to your address

# Check balance
akash query bank balances $(akash keys show my-rofl-wallet -a)
```

### 2. Create Deployment Certificate
```bash
export AKASH_KEYRING_BACKEND=os
export AKASH_ACCOUNT_ADDRESS=$(akash keys show my-rofl-wallet -a)
export AKASH_NET="https://raw.githubusercontent.com/akash-network/net/main/mainnet"
export AKASH_CHAIN_ID="$(curl -s "$AKASH_NET/chain-id.txt")"
export AKASH_NODE="$(curl -s "$AKASH_NET/rpc-nodes.txt" | head -1)"

# Create certificate (one-time)
akash tx cert generate client --from my-rofl-wallet --chain-id $AKASH_CHAIN_ID

# Publish certificate
akash tx cert publish client --from my-rofl-wallet --chain-id $AKASH_CHAIN_ID
```

### 3. Update deploy.yaml
Edit `deploy.yaml` and replace:
```yaml
# Line with YOUR_USERNAME/YOUR_REPO
git clone https://github.com/YOUR_GITHUB_USERNAME/oasis-rofl-node.git /app
```

### 4. Deploy to Akash
```bash
# Create deployment
akash tx deployment create deploy.yaml \
  --from my-rofl-wallet \
  --chain-id $AKASH_CHAIN_ID \
  --node $AKASH_NODE

# Save deployment sequence from output
export AKASH_DSEQ=<deployment-sequence-number>

# Wait ~30 seconds, then query bids
akash query market bid list \
  --owner $AKASH_ACCOUNT_ADDRESS \
  --node $AKASH_NODE \
  --state open

# Choose a provider and create lease
export AKASH_PROVIDER=<provider-address-from-bids>

akash tx market lease create \
  --dseq $AKASH_DSEQ \
  --provider $AKASH_PROVIDER \
  --from my-rofl-wallet \
  --chain-id $AKASH_CHAIN_ID \
  --node $AKASH_NODE

# Send manifest
akash provider send-manifest deploy.yaml \
  --dseq $AKASH_DSEQ \
  --provider $AKASH_PROVIDER \
  --from my-rofl-wallet \
  --home ~/.akash
```

### 5. Monitor Deployment
```bash
# Check status
akash provider lease-status \
  --dseq $AKASH_DSEQ \
  --provider $AKASH_PROVIDER \
  --from my-rofl-wallet

# View logs
akash provider lease-logs \
  --dseq $AKASH_DSEQ \
  --provider $AKASH_PROVIDER \
  --from my-rofl-wallet \
  --follow

# Get shell access
akash provider lease-shell \
  --dseq $AKASH_DSEQ \
  --provider $AKASH_PROVIDER \
  --from my-rofl-wallet
```

### 6. Get Node Info
```bash
# Once deployed, shell into the container
akash provider lease-shell \
  --dseq $AKASH_DSEQ \
  --provider $AKASH_PROVIDER \
  --from my-rofl-wallet

# Inside container:
cd /app
./scripts/check-status.sh
./scripts/get-node-address.sh
```

## 🔧 Configure Node on Akash

### Update Config with Public IP
```bash
# Get your deployment's public IP
akash provider lease-status \
  --dseq $AKASH_DSEQ \
  --provider $AKASH_PROVIDER \
  --from my-rofl-wallet | grep -A5 "forwarded_ports"

# Note the external IP
# Shell into container and update config
vi /app/node/etc/config.yml
# Add: external_address: <public-ip>:26656

# Restart node
pkill oasis-node
./scripts/start-node.sh
```

## 💰 Cost Tracking

```bash
# Check current spend
akash query market lease list \
  --owner $AKASH_ACCOUNT_ADDRESS \
  --state active

# Calculate monthly cost
# Price per block × blocks per day (7200) × 30 days
```

## 🛑 Stop/Update Deployment

### Close Deployment
```bash
akash tx deployment close \
  --dseq $AKASH_DSEQ \
  --from my-rofl-wallet \
  --chain-id $AKASH_CHAIN_ID
```

### Update Deployment
```bash
# Edit deploy.yaml with changes
# Update deployment
akash tx deployment update deploy.yaml \
  --dseq $AKASH_DSEQ \
  --from my-rofl-wallet \
  --chain-id $AKASH_CHAIN_ID
```

## 📋 Checklist

### Before Pushing to GitHub
- [ ] Verify no `.pem` or `.key` files in git
- [ ] Check `.env` is not committed
- [ ] Review `.gitignore` is working
- [ ] Remove any hardcoded secrets from config files

### Before Deploying to Akash
- [ ] Update GitHub URL in `deploy.yaml`
- [ ] Have 5+ AKT in wallet
- [ ] Certificate created and published
- [ ] Network endpoints configured

### After Deployment
- [ ] Verify node is running
- [ ] Check sync status
- [ ] Get node funding address
- [ ] Fund node account on Sapphire
- [ ] Register ROFL provider
- [ ] Monitor logs for issues

## 🆘 Troubleshooting

### "insufficient fees" error
Add `--fees 5000uakt` to your commands

### Can't find providers
```bash
# List all providers
akash provider list

# Filter by attributes
akash provider list --attributes region=us-west
```

### Deployment stuck
```bash
# Check deployment status
akash query deployment get \
  --owner $AKASH_ACCOUNT_ADDRESS \
  --dseq $AKASH_DSEQ

# Close and recreate if needed
```

### Need to backup identity
```bash
# Copy from Akash deployment
akash provider lease-shell ... 
# Inside: cat /app/node/data/identity.pem
# Save locally

# Or use kubectl if provider supports it
```

## 🔗 Useful Links

- [Akash Docs](https://docs.akash.network/)
- [Akash Console](https://console.akash.network/) (Web UI alternative)
- [Cloudmos Deploy](https://deploy.cloudmos.io/) (Easier deployment UI)
- [Akash Discord](https://discord.akash.network/)
- [ROFL Node Docs](https://docs.oasis.io/node/run-your-node/rofl-node)

## 💡 Pro Tips

1. **Use Cloudmos Deploy UI** for easier deployment without CLI
2. **Start with testnet** to verify everything works
3. **Monitor costs daily** during first week
4. **Keep local backup** of identity.pem
5. **Document your DSEQ and provider** for easy access
6. **Set calendar reminders** to check node status weekly
