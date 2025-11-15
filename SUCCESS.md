# SUCCESS: Oasis Sapphire Testnet Client Node Running!

## Deployment 16 - WORKING ✅

**Deployment ID:** 24205365  
**Provider:** akash1k8wqz7znj8mj783nk0nz30xztnck4r3whj56nf (Poland)  
**Status:** Node successfully syncing with Oasis Sapphire testnet  
**Date:** November 15, 2025

## Key Achievements

### ✅ Node is Running
- Successfully started oasis-node in client mode
- Processing blocks at ~32-40 blocks/second
- Currently syncing: Height 17,756,781 (target: 29,353,835)
- 13 outbound peer connections established

### ✅ Correct Configuration Found
After 16 deployment iterations, the correct config structure is:

```yaml
mode: client

common:
  data_dir: /app/node/data
  log:
    format: JSON
    level:
      default: info

genesis:
  file: /app/node/etc/genesis.json

consensus:
  listen_address: tcp://0.0.0.0:26656

p2p:
  seeds:
    - "HcDFrTp/MqRHtju5bCx6TIhIMd6X/0ZQ3lUG73q5898=@35.247.24.212:26656"
    - "kqsc8ETIgG9LCmW5HhSEUW80WIpwKhS7hRQd8FrnkJ0=@34.140.116.202:26656"
```

**Critical Fix:** Seeds must be in the `p2p` section, NOT under `consensus.tendermint`.

## Deployment History

### Iterations 1-15: Progressive Debugging
1. **Deployment 1-2:** Repository access and tar extraction issues
2. **Deployment 3-5:** Data directory creation and permissions
3. **Deployment 6-10:** Config validation errors (datadir, runtimes, ias.proxy_addr, etc.)
4. **Deployment 11-13:** Mode switching (validator → client), tendermint field errors
5. **Deployment 14:** Seed format fix (hex → base64), but config structure still wrong
6. **Deployment 15:** Attempted consensus.tendermint.p2p.seed - field not found error
7. **Deployment 16:** ✅ Moved seeds to p2p section - SUCCESS!

### Total Cost
- ~15 deployments × $0.05 = ~$0.75 USD spent on iterative debugging
- Remaining wallet balance: ~49.3 AKT (~$98.60 USD)

## Technical Stack

### Oasis Network
- **Network:** Sapphire Testnet
- **Runtime ID:** 000000000000000000000000000000000000000000000000a6d1e3ebf60dff6c
- **Software:** oasis-node v24.2, oasis-core-runtime-loader v24.2, oasis-cli v0.10.0
- **Genesis:** From official Oasis testnet
- **Seeds:** Official base64-encoded testnet node IDs

### Akash Network
- **Network:** akashnet-2
- **Provider:** Poland-based provider (reliable, cost-effective)
- **Resources:** 8 CPU, 32GB RAM, 200GB storage
- **Cost:** ~60 uakt/block (~$12-15/month estimated)

### Container Setup
- **Base:** Ubuntu 22.04
- **User:** Non-root user "oasis" with sudo privileges
- **Ports:** 26656 (consensus), 9200 (runtime)
- **Repository:** https://github.com/inversiones536/oasis_rofl_node (PUBLIC)

## Next Steps

### Immediate
1. ✅ Basic client node is running and syncing
2. ⏳ Wait for full sync (may take several hours given 11M blocks behind)
3. ⏳ Monitor sync progress and peer connections

### Future: ROFL with Mock SGX
Once basic node is fully synced and stable:
1. Access container shell
2. Execute `./scripts/build-rofl-app.sh` to build ROFL from source with `--features debug-mock-sgx`
3. Update config to load custom ROFL runtime
4. Test ROFL functionality without real SGX hardware

## Lessons Learned

### Config Structure Insights
1. Oasis node config parser is extremely strict about field names and structure
2. Errors only appear at runtime, not during validation
3. Different modes (client vs compute) have different valid config fields
4. CometBFT is Oasis's consensus engine (not related to Akash)
5. Seed node IDs must be base64-encoded, not hex
6. P2P configuration is at the top level, not nested under consensus

### Cloud Deployment Strategy
1. Iterative debugging on cloud infrastructure is viable and cost-effective
2. Each deployment costs ~$0.05, mostly recoverable via escrow
3. GitHub integration for automatic updates works well
4. Non-root user implementation is critical for security

### User's Approach Was Correct
The user challenged the agent's premature conclusions:
- **User:** "wait why do I need bare metal?"
- **User:** "I think you might be giving up too easily"
- **Result:** User was correct - mock SGX build strategy is the right path forward

## Commands for Monitoring

Check logs:
```bash
provider-services lease-logs --dseq 24205365 --provider akash1k8wqz7znj8mj783nk0nz30xztnck4r3whj56nf --from my-rofl-wallet --node https://rpc.akashnet.net:443 --keyring-backend os --home ~/.akash
```

Check sync status:
```bash
provider-services lease-logs --dseq 24205365 --provider akash1k8wqz7znj8mj783nk0nz30xztnck4r3whj56nf --from my-rofl-wallet --node https://rpc.akashnet.net:443 --keyring-backend os --home ~/.akash 2>&1 | grep "Block Sync Rate"
```

Access shell (once needed):
```bash
provider-services lease-shell --dseq 24205365 --provider akash1k8wqz7znj8mj783nk0nz30xztnck4r3whj56nf --from my-rofl-wallet --node https://rpc.akashnet.net:443 --keyring-backend os --home ~/.akash /bin/bash
```

## Conclusion

After 16 iterative deployments and progressive debugging, we successfully launched an Oasis Sapphire testnet client node on Akash Network. The node is currently syncing blocks and maintaining peer connections.

The iterative debugging approach proved effective:
- Each deployment revealed one more layer of configuration requirements
- Total cost remained minimal (~$0.75)
- Escrow recovery kept wallet healthy
- User's persistence and challenge of premature conclusions was key to success

**Status:** Basic client node operational ✅  
**Next Goal:** Build and test ROFL with mock SGX 🎯
