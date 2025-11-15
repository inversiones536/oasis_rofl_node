# Deploying Oasis ROFL Node on Akash

This guide covers deploying your Oasis ROFL node on Akash Network, a decentralized cloud computing marketplace.

## 🌟 Why Akash for ROFL Nodes?

- **Cost-effective**: Typically 2-3x cheaper than traditional cloud providers
- **Decentralized**: No single point of failure
- **TEE Support**: Providers with Intel SGX/TDX hardware available
- **Persistent Storage**: Support for persistent volumes
- **Global Network**: Providers worldwide

## 📋 Prerequisites

### On Your Local Machine
1. **Akash CLI** installed ([Installation Guide](https://docs.akash.network/guides/cli/installation))
2. **AKT tokens** for deployment (you'll need ~5-10 AKT)
3. **Wallet** with AKT balance

### Required for ROFL Node
- Provider with **Intel TDX or SGX** capability
- Minimum **8GB RAM**, recommended **32GB+**
- **100GB+** persistent storage
- **High uptime** guarantee

## 🚀 Deployment Steps

### 1. Clone Repository on Akash Provider

Since you're pushing to GitHub, you can clone directly on the provider:

```bash
# SSH into your Akash deployment
# Or use the deploy.yaml to run git clone automatically
```

### 2. Create Akash Deployment Manifest

Create `deploy.yaml` in your project root:

```yaml
---
version: "2.0"

services:
  oasis-rofl-node:
    image: ubuntu:22.04
    expose:
      - port: 26656
        as: 26656
        to:
          - global: true
        protocol: tcp
      - port: 9200
        as: 9200
        to:
          - global: true
        protocol: tcp
    env:
      - NETWORK=testnet
      - OASIS_NODE_VERSION=24.2
    command:
      - "bash"
      - "-c"
    args:
      - >-
        apt-get update &&
        apt-get install -y curl jq git build-essential &&
        git clone YOUR_GITHUB_REPO_URL /app &&
        cd /app &&
        chmod +x scripts/*.sh &&
        ./scripts/setup.sh &&
        exec ./scripts/start-node.sh

profiles:
  compute:
    rofl-node:
      resources:
        cpu:
          units: 8.0
        memory:
          size: 32Gi
        storage:
          - size: 200Gi
            attributes:
              persistent: true
              class: beta3
        
        # TEE requirement
        gpu:
          units: 0
          attributes:
            vendor:
              intel:
                - sgx
                - tdx

  placement:
    akash:
      pricing:
        rofl-node:
          denom: uakt
          amount: 10000  # Adjust based on market rates

deployment:
  oasis-rofl-node:
    akash:
      profile: rofl-node
      count: 1
```

### 3. Alternative: Docker-based Deployment

For better control, create a Dockerfile:

```dockerfile
FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && \
    apt-get install -y \
    curl \
    jq \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create oasis user for security
RUN useradd -r -s /bin/false oasis

# Set working directory
WORKDIR /app

# Copy project files
COPY . .

# Make scripts executable
RUN chmod +x scripts/*.sh

# Run setup
RUN ./scripts/setup.sh

# Expose ports
EXPOSE 26656 9200

# Set user
USER oasis

# Start node
CMD ["./scripts/start-node.sh"]
```

Then update `deploy.yaml` to use your Docker image:

```yaml
services:
  oasis-rofl-node:
    image: your-dockerhub-username/oasis-rofl-node:latest
    # ... rest of configuration
```

### 4. Deploy to Akash

```bash
# Set your account
export AKASH_ACCOUNT_ADDRESS=<your-akash-address>
export AKASH_KEYRING_BACKEND=os
export AKASH_CHAIN_ID=akashnet-2
export AKASH_NODE=https://rpc.akash.network:443

# Create deployment certificate (one-time)
akash tx cert generate client --from=$AKASH_ACCOUNT_ADDRESS

# Publish certificate
akash tx cert publish client --from=$AKASH_ACCOUNT_ADDRESS

# Create deployment
akash tx deployment create deploy.yaml --from=$AKASH_ACCOUNT_ADDRESS

# Get deployment ID from output, then query bids
akash query market bid list --owner=$AKASH_ACCOUNT_ADDRESS

# Create lease with chosen provider
akash tx market lease create \
  --dseq=<deployment-sequence> \
  --provider=<provider-address> \
  --from=$AKASH_ACCOUNT_ADDRESS

# Send manifest
akash provider send-manifest deploy.yaml \
  --dseq=<deployment-sequence> \
  --provider=<provider-address> \
  --from=$AKASH_ACCOUNT_ADDRESS

# Get service status and logs
akash provider lease-status \
  --dseq=<deployment-sequence> \
  --provider=<provider-address> \
  --from=$AKASH_ACCOUNT_ADDRESS

akash provider lease-logs \
  --dseq=<deployment-sequence> \
  --provider=<provider-address> \
  --from=$AKASH_ACCOUNT_ADDRESS
```

## 🔧 Configuration for Akash

### Environment Variables

Set these in your deployment or create a ConfigMap:

```yaml
env:
  - NETWORK=testnet
  - OASIS_NODE_VERSION=24.2
  - PROVIDER_ADDRESS=your-oasis-provider-address
  - PAYMENT_ADDRESS=your-payment-address
```

### Persistent Storage

Critical for ROFL nodes:
- Node identity persists across restarts
- ROFL app data maintained
- Blockchain state preserved

Ensure `persistent: true` in your storage configuration.

### Networking

Your Akash deployment will have a public IP. Update your `config.yml`:

```yaml
consensus:
  external_address: <akash-public-ip>:26656
```

## 🔐 Security Considerations

### 1. Secrets Management

**NEVER commit secrets to GitHub!**

Use Akash secrets for sensitive data:

```bash
# Create secret for node identity
akash provider secret create identity.pem \
  --dseq=<deployment-sequence> \
  --provider=<provider-address> \
  --from=$AKASH_ACCOUNT_ADDRESS \
  --file=/path/to/identity.pem
```

Reference in deploy.yaml:
```yaml
env:
  - name: NODE_IDENTITY
    valueFrom:
      secretRef:
        name: identity.pem
```

### 2. Pre-generate Identity

Before deploying:
```bash
# Generate locally
./scripts/setup.sh

# Backup identity
cp node/data/identity.pem ~/backups/rofl-identity.pem

# Upload to Akash as secret
```

### 3. Firewall Rules

The firewall script won't work on Akash. Instead:
- Use network policies in deployment
- Provider isolation is handled at provider level
- Focus on application-level security

## 📊 Monitoring on Akash

### Check Logs
```bash
akash provider lease-logs \
  --dseq=<deployment-sequence> \
  --provider=<provider-address> \
  --from=$AKASH_ACCOUNT_ADDRESS \
  --follow
```

### Check Service Status
```bash
akash provider lease-status \
  --dseq=<deployment-sequence> \
  --provider=<provider-address> \
  --from=$AKASH_ACCOUNT_ADDRESS
```

### Shell Access
```bash
akash provider lease-shell \
  --dseq=<deployment-sequence> \
  --provider=<provider-address> \
  --from=$AKASH_ACCOUNT_ADDRESS
```

## 💰 Cost Estimation

Typical monthly costs on Akash:
- **Small node** (8 CPU, 16GB RAM, 100GB storage): ~$20-40/month
- **Medium node** (16 CPU, 32GB RAM, 200GB storage): ~$50-80/month
- **Large node** (32 CPU, 64GB RAM, 500GB storage): ~$100-150/month

Compare to AWS: $200-500+/month for equivalent specs

## 🔄 Updates and Maintenance

### Update Node Software
```bash
# SSH into deployment
akash provider lease-shell ...

# Pull latest from git
cd /app
git pull

# Run update script
./scripts/setup.sh

# Restart node
pkill oasis-node
./scripts/start-node.sh
```

### Update Deployment
```bash
# Modify deploy.yaml
# Update deployment
akash tx deployment update deploy.yaml \
  --dseq=<deployment-sequence> \
  --from=$AKASH_ACCOUNT_ADDRESS
```

## ⚠️ Important Notes

1. **TEE Availability**: Not all Akash providers have TEE hardware. Filter carefully.
2. **Provider Uptime**: Choose providers with proven track record
3. **Network Speed**: Ensure provider has adequate bandwidth for blockchain sync
4. **Data Persistence**: Always use persistent storage for production nodes
5. **Backup Strategy**: Regularly backup identity.pem and important data
6. **Geographic Distribution**: Consider multiple deployments across regions

## 🔍 Finding TEE-Capable Providers

### Using Akash Provider Attributes

Look for providers advertising:
```
- intel/sgx
- intel/tdx
- tee-enabled
```

Check Akash provider list:
```bash
akash provider list --attributes tee
```

### Recommended Providers
Check the Akash Discord for community-recommended providers with TEE support.

## 📚 Additional Resources

- [Akash Documentation](https://docs.akash.network/)
- [Akash Discord](https://discord.akash.network/)
- [Akash Awesome List](https://github.com/ovrclk/awesome-akash)
- [Provider Attributes Guide](https://docs.akash.network/providers/provider-features)

## 🆘 Troubleshooting

### Deployment Won't Start
- Check resource requirements match provider capabilities
- Verify TEE attributes are correct
- Check Akash wallet has sufficient AKT

### Can't Connect to Node
- Verify ports 26656 and 9200 are exposed globally
- Check provider firewall rules
- Ensure external_address is set correctly

### Sync Issues
- Verify internet connectivity from provider
- Check seed nodes are accessible
- Increase timeout values if needed

### Persistent Storage Issues
- Ensure provider supports persistent storage
- Verify volume class is correct
- Check mount points in deployment

## 🎯 Quick Start Checklist

- [ ] Push code to GitHub (without secrets!)
- [ ] Install Akash CLI
- [ ] Fund Akash wallet with AKT
- [ ] Create deployment certificate
- [ ] Customize deploy.yaml
- [ ] Find TEE-capable provider
- [ ] Create deployment
- [ ] Accept bid and create lease
- [ ] Upload node identity as secret
- [ ] Send manifest
- [ ] Verify node is running
- [ ] Fund Oasis node account
- [ ] Register ROFL provider
- [ ] Monitor logs and status

## 🔄 CI/CD Integration

For automated deployments, consider:
- GitHub Actions to build Docker image
- Automatic deployment on git push
- Health check monitoring
- Auto-restart on failure

Example GitHub Action coming soon!
