# Quick Reference Guide

## Essential Commands

### Initial Setup
```bash
# Run initial setup (downloads binaries, genesis, etc.)
./scripts/setup.sh

# For mainnet
NETWORK=mainnet ./scripts/setup.sh
```

### Node Operations
```bash
# Start node
./scripts/start-node.sh

# Check status
./scripts/check-status.sh

# Get node address for funding
./scripts/get-node-address.sh

# View ROFL app logs
./scripts/view-logs.sh rofl1qr...

# View all logs
tail -f node/data/node.log
```

### Account Management
```bash
# Create new account
./node/bin/oasis account create

# List accounts
./node/bin/oasis account list

# Show account balance
./node/bin/oasis account show
```

### ROFL Provider Management
```bash
# Initialize provider config
./node/bin/oasis rofl provider init

# Create/register provider (requires 100 token deposit)
./node/bin/oasis rofl provider create

# Update provider configuration
./node/bin/oasis rofl provider update

# Show provider details
./node/bin/oasis rofl provider show

# Deregister provider (returns deposit)
./node/bin/oasis rofl provider remove
```

### Funding
```bash
# Testnet faucet
# Visit: https://faucet.testnet.oasis.io/?paratime=sapphire

# Mainnet transfer
./node/bin/oasis account transfer <amount> <recipient-address>
```

## Important Addresses

### Mainnet
- Seed nodes: Check https://docs.oasis.io/node/network/mainnet
- Sapphire runtime ID: `000000000000000000000000000000000000000000000000f80306c9858e7279`

### Testnet
- Seed nodes: Check https://docs.oasis.io/node/network/testnet
- Sapphire runtime ID: `000000000000000000000000000000000000000000000000a6d1e3ebf60dff6c`
- Faucet: https://faucet.testnet.oasis.io/?paratime=sapphire

### ROFL Scheduler App ID
- `rofl1qrqw99h0f7az3hwt2cl7yeew3wtz0fxunu7luyfg`

## Configuration Files

### node/etc/config.yml
Main node configuration:
- Network settings (ports, seeds)
- Runtime configuration
- ROFL scheduler settings
- Resource allocations

### rofl-provider.yaml
ROFL marketplace provider configuration:
- Node IDs
- Instance offers (small, medium, large)
- Pricing
- Payment address

## Common Issues

### Node won't start
- Check config.yml syntax
- Verify seed nodes are correct
- Ensure genesis.json exists
- Check binary permissions

### Can't sync
- Verify network connectivity
- Check seed nodes are reachable
- Ensure ports 26656 and 9200 are open

### ROFL apps not deploying
- Verify provider is registered: `./node/bin/oasis rofl provider show`
- Check scheduler logs: `./scripts/view-logs.sh rofl.rofl1qrqw99h0f7az3hwt2cl7yeew3wtz0fxunu7luyfg`
- Ensure node account has sufficient funds
- Verify resource capacity in config.yml

## Resource Planning

### Minimum Requirements
- CPU: 4 cores
- RAM: 8 GB
- Storage: 100 GB
- TEE: Intel TDX or SGX

### Recommended for Marketplace
- CPU: 24+ cores
- RAM: 64+ GB
- Storage: 512+ GB
- High-speed SSD
- Stable network with high uptime

## Security Checklist

- [ ] Firewall configured (./scripts/configure-firewall.sh)
- [ ] Ports 26656 and 9200 open and accessible
- [ ] Identity key backed up (node/data/identity.pem)
- [ ] Account keys secured
- [ ] TEE verified and functional
- [ ] Regular monitoring of logs
- [ ] Node server access restricted

## Monitoring

### Check Node Health
```bash
# Node status
./scripts/check-status.sh

# Recent logs
tail -n 100 node/data/node.log

# Scheduler status
grep rofl.rofl1qrqw99h0f7az3hwt2cl7yeew3wtz0fxunu7luyfg node/data/node.log | tail -20
```

### Check ROFL Instances
```bash
# List volumes (persistent storage)
ls -la node/data/runtimes/volumes/

# Check volume descriptors
cat node/data/runtimes/volumes/*/descriptor.json
```

## Useful Links

- Documentation: https://docs.oasis.io/
- ParaTime Client: https://docs.oasis.io/node/run-your-node/paratime-client-node
- ROFL Node: https://docs.oasis.io/node/run-your-node/rofl-node
- Marketplace: https://docs.oasis.io/build/rofl/features/marketplace
- Discord: https://oasis.io/discord
- Telegram: https://t.me/oasisprotocolcommunity
