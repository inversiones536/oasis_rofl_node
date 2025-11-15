# Oasis Sapphire ROFL Node Setup

This repository contains configuration and scripts for running an Oasis Network ROFL (Runtime Off-chain Logic) node on the Sapphire ParaTime. ROFL nodes execute third-party applications inside a Trusted Execution Environment (TEE) and can interact with smart contracts.

## 📋 Prerequisites

### Hardware Requirements
- **TEE-capable hardware**: Intel TDX or SGX processor
- **CPU**: Multi-core processor (minimum 4 cores, recommended 24+ for marketplace hosting)
- **RAM**: Minimum 8GB, recommended 64GB+ for hosting multiple ROFLs
- **Storage**: 100GB+ available disk space (SSD recommended)
- **Network**: Stable internet connection with open ports 26656 (consensus) and 9200 (P2P)

### Software Requirements
- Linux-based OS (Ubuntu 20.04+ recommended) or macOS
- Docker (optional, for containerized deployment)
- Root/sudo access (for firewall configuration)

### TEE Setup
Follow the [Oasis TEE setup guide](https://docs.oasis.io/node/run-your-node/prerequisites/set-up-tee) to:
- Enable Intel TDX or SGX in BIOS
- Install necessary drivers and software
- Verify TEE functionality

## 🚀 Quick Start

### 1. Clone and Setup

```bash
# Navigate to the project directory
cd rofl-node

# Make scripts executable
chmod +x scripts/*.sh

# Run setup (downloads binaries, genesis file, and ROFL scheduler)
./scripts/setup.sh
```

By default, this sets up for **testnet**. For mainnet:
```bash
NETWORK=mainnet ./scripts/setup.sh
```

### 2. Configure Node

Edit `node/etc/config.yml` and update:
- `{{ seed_node_address }}`: Get from [Mainnet](https://docs.oasis.io/node/network/mainnet) or [Testnet](https://docs.oasis.io/node/network/testnet)
- `REPLACE_WITH_YOUR_PROVIDER_ADDRESS`: Your Oasis account address (bech32 format)
- Adjust resource allocations (memory, CPUs, storage) based on your hardware

### 3. Configure ROFL Provider

Edit `rofl-provider.yaml` and set:
- `provider`: Your Oasis CLI account name
- `nodes`: Your node ID (obtained during setup)
- `payment_address`: Where you'll receive hosting fees
- `offers`: Define instance sizes and pricing

### 4. Create and Fund Account

```bash
# Create account with Oasis CLI
./node/bin/oasis account create

# Get your node's funding address
./scripts/get-node-address.sh

# Fund the address:
# Testnet: https://faucet.testnet.oasis.io/?paratime=sapphire
# Mainnet: Transfer tokens to the address
```

### 5. Configure Firewall (Optional but Recommended)

For security, prevent ROFL apps from accessing your local network:

```bash
# Review and adjust settings in the script
sudo ./scripts/configure-firewall.sh
```

### 6. Register as ROFL Provider

```bash
# Initialize provider configuration
./node/bin/oasis rofl provider init

# Register on-chain (requires 100 token deposit, refundable)
./node/bin/oasis rofl provider create

# Verify registration
./node/bin/oasis rofl provider show
```

### 7. Start Node

```bash
# Start the node
./scripts/start-node.sh

# In another terminal, check status
./scripts/check-status.sh
```

## 📁 Project Structure

```
rofl-node/
├── node/
│   ├── bin/                    # Binary files (oasis-node, oasis CLI, etc.)
│   ├── data/                   # Node data and state
│   ├── etc/
│   │   ├── config.yml         # Node configuration
│   │   └── genesis.json       # Network genesis file
│   └── rofls/                 # ROFL app bundles
├── scripts/
│   ├── setup.sh               # Initial setup script
│   ├── start-node.sh          # Start the node
│   ├── check-status.sh        # Check node status
│   ├── get-node-address.sh    # Get funding address
│   └── configure-firewall.sh  # Security configuration
├── rofl-provider.yaml         # ROFL marketplace provider config
└── README.md                  # This file
```

## 🔧 Configuration Details

### Node Modes

#### Standard Client Mode (Default)
- Full consensus client with state sync
- Requires more resources and disk space
- Higher reliability and availability

#### Stateless Client Mode (Recommended for ROFL)
- Fetches state via gRPC from provider nodes
- Faster bootstrapping, fewer resources
- Enable by setting `mode: client-stateless` in `config.yml`

### ROFL Hosting Options

#### 1. Marketplace Hosting (Recommended)
- Automated ROFL deployment via marketplace
- Users deploy with: `oasis rofl deploy --provider <your-address>`
- Scheduler app manages ROFL lifecycle
- Dynamic resource allocation

#### 2. Direct Bundle Hosting
- Manually copy ROFL bundles to `node/rofls/`
- Add bundle paths to `runtime.paths` in config
- Static configuration, manual management

## 📊 Monitoring and Operations

### Check Node Status
```bash
./scripts/check-status.sh
```

### View Logs
```bash
# All logs
tail -f node/data/node.log

# Filter by ROFL app ID
grep "rofl.rofl1qr..." node/data/node.log

# Extract messages only
grep "rofl.rofl1qr..." node/data/node.log | jq -r '.msg'
```

### Check ROFL Scheduler
```bash
# Check scheduler logs
grep rofl.rofl1qrqw99h0f7az3hwt2cl7yeew3wtz0fxunu7luyfg node/data/node.log
```

### Persistent Storage
ROFL app data is stored in: `node/data/runtimes/volumes/{hex-value}/`
- Persists across ROFL upgrades and restarts
- Each volume has a `descriptor.json` with metadata

## 🌐 Port Configuration

Ensure these ports are open and accessible:

- **26656** (TCP/UDP): Consensus P2P
- **9200** (TCP/UDP): Runtime P2P
- **Custom ports**: Any ports exposed for ROFL apps (configure in `config.yml`)

Example port forwarding for ROFL app:
```yaml
runtime:
  runtimes:
    - id: "000000000000000000000000000000000000000000000000a6d1e3ebf60dff6c"
      components:
        - id: rofl.rofl1qp...
          networking:
            incoming:
              - ip: 192.168.0.10
                protocol: tcp
                src_port: 443
                dst_port: 443
```

## 🔐 Security Best Practices

1. **Firewall**: Always configure iptables to isolate ROFL apps from LAN
2. **Updates**: Keep binaries updated to latest stable versions
3. **Monitoring**: Regularly check logs for suspicious activity
4. **Backups**: Backup `node/data/identity.pem` and account keys
5. **Access Control**: Restrict shell access to node server
6. **Network Isolation**: Run ROFL node on isolated network segment

## 💰 Economics

### Provider Registration
- **Deposit Required**: 100 tokens (refundable on deregistration)
- **Transaction Fees**: Small amount for registration and updates

### Hosting Revenue
- Set your own pricing in `rofl-provider.yaml`
- Charged hourly based on resource usage
- Payments received at configured `payment_address`

### Node Operating Costs
- Transaction fees for ROFL registration and updates (paid by node account)
- Ensure node account maintains sufficient balance

## 🛠️ Troubleshooting

### Node Won't Start
```bash
# Check config syntax
cat node/etc/config.yml

# Verify binaries exist
ls -la node/bin/

# Check genesis file
ls -la node/etc/genesis.json
```

### Sync Issues
```bash
# Check consensus status
./scripts/check-status.sh

# Verify seed nodes are reachable
# Update seed nodes in config.yml
```

### ROFL Apps Not Starting
```bash
# Check scheduler logs
grep rofl.rofl1qrqw99h0f7az3hwt2cl7yeew3wtz0fxunu7luyfg node/data/node.log | tail -20

# Verify provider registration
./node/bin/oasis rofl provider show

# Check resource capacity in config.yml
```

### TEE Issues
```bash
# Verify TEE is enabled
# For Intel TDX:
dmesg | grep -i tdx

# For Intel SGX:
./node/bin/oasis-node identity init --datadir node/data
```

## 📚 Additional Resources

- [Oasis Documentation](https://docs.oasis.io/)
- [ParaTime Client Node Guide](https://docs.oasis.io/node/run-your-node/paratime-client-node)
- [ROFL Node Guide](https://docs.oasis.io/node/run-your-node/rofl-node)
- [ROFL Marketplace](https://docs.oasis.io/build/rofl/features/marketplace)
- [Oasis CLI Documentation](https://docs.oasis.io/build/tools/cli/)
- [Network Parameters - Mainnet](https://docs.oasis.io/node/network/mainnet)
- [Network Parameters - Testnet](https://docs.oasis.io/node/network/testnet)

## 🤝 Support

- [Oasis Discord](https://oasis.io/discord)
- [Oasis Telegram](https://t.me/oasisprotocolcommunity)
- [GitHub Issues](https://github.com/oasisprotocol/oasis-core/issues)

## 📄 License

This setup is provided as-is for use with the Oasis Network. Refer to individual component licenses:
- Oasis Core: [Apache 2.0](https://www.apache.org/licenses/LICENSE-2.0)
- Oasis CLI: [Apache 2.0](https://www.apache.org/licenses/LICENSE-2.0)

## ⚠️ Important Notes

1. **Testnet First**: Always test on testnet before deploying to mainnet
2. **Resource Planning**: Ensure adequate resources for your offered capacity
3. **Uptime**: Maintain high uptime for reliable ROFL hosting
4. **Updates**: Monitor for network upgrades and update accordingly
5. **Backups**: Regular backups of identity and account keys are critical
