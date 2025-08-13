# Hyperledger Besu 4-Node Network Deployment

Deploy a 4-node Hyperledger Besu blockchain network across 4 different remote VMs with Docker, creating a decentralized network where nodes share enodes for peer discovery.

## Prerequisites

On each VM:
- Docker (version 20.0+)
- Docker Compose (version 2.0+)  
- curl
- Internet connectivity
- Open firewall ports: 8550 (HTTP RPC), 8546 (WebSocket), 30310 (P2P), 30303 (bootnode)

## Scripts Overview

The deployment uses 4 scripts that must be run in sequence:

1. `generate-keys.sh` - Generates unique node keys and enode for each VM
2. `init-blockchain.sh` - Creates the genesis configuration with all validator addresses
3. `start-first-node.sh` - Starts the bootstrap node (run on VM1 only)
4. `start-node.sh` - Starts other nodes and connects them to the bootstrap node

## Deployment Steps

### Step 1: Clone and Setup on All VMs

```bash
git clone <this-repository>
cd besu
chmod +x *.sh
```

### Step 2: Generate Keys on Each VM

Run on all 4 VMs:

```bash
# Run on each VM
./generate-keys.sh
```

This creates:
- `DVRE-Node/data/key` - Private key
- `DVRE-Node/data/key.pub` - Public key  
- `DVRE-Node/node.address` - Node's validator address
- `DVRE-Node/node.enode` - Node's enode URL (with port 30310)

### Step 3: Collect Validator Addresses

From each VM, collect the validator address:

```bash
# On VM1
cat DVRE-Node/node.address
# Copy this address - it's VALIDATOR_ADDRESS_1

# On VM2  
cat DVRE-Node/node.address
# Copy this address - it's VALIDATOR_ADDRESS_2

# On VM3
cat DVRE-Node/node.address  
# Copy this address - it's VALIDATOR_ADDRESS_3

# On VM4
cat DVRE-Node/node.address
# Copy this address - it's VALIDATOR_ADDRESS_4
```

### Step 4: Initialize Blockchain on All VMs

Run on each VM with the collected addresses. The genesis.json must be identical on all nodes.

```bash
# On VM1 (using addresses from VM2, VM3, VM4)
./init-blockchain.sh <VALIDATOR_ADDRESS_2> <VALIDATOR_ADDRESS_3> <VALIDATOR_ADDRESS_4>

# On VM2 (using addresses from VM1, VM3, VM4) 
./init-blockchain.sh <VALIDATOR_ADDRESS_1> <VALIDATOR_ADDRESS_3> <VALIDATOR_ADDRESS_4>

# On VM3 (using addresses from VM1, VM2, VM4)
./init-blockchain.sh <VALIDATOR_ADDRESS_1> <VALIDATOR_ADDRESS_2> <VALIDATOR_ADDRESS_4>

# On VM4 (using addresses from VM1, VM2, VM3)
./init-blockchain.sh <VALIDATOR_ADDRESS_1> <VALIDATOR_ADDRESS_2> <VALIDATOR_ADDRESS_3>
```

### Step 5: Start the Bootstrap Node

Start the first node (VM1) - this becomes the bootstrap node:

```bash
# On VM1 only
./start-first-node.sh
```

Copy the bootstrap enode from the output or from:
```bash
cat DVRE-Node/node.enode
```

### Step 6: Start Other Nodes

Start the remaining nodes using the bootstrap enode:

```bash
# On VM2
./start-node.sh <BOOTSTRAP_ENODE_FROM_VM1>

# On VM3  
./start-node.sh <BOOTSTRAP_ENODE_FROM_VM1>

# On VM4
./start-node.sh <BOOTSTRAP_ENODE_FROM_VM1>
```

## Network Configuration

- **Consensus**: IBFT 2.0 (Istanbul Byzantine Fault Tolerance)
- **Chain ID**: 1337
- **Block Time**: 2 seconds
- **Validators**: All 4 nodes participate in consensus
- **Gas Limit**: Unlimited (for testing)
- **Profile**: ENTERPRISE

## Network Endpoints

Each running node exposes:
- **HTTP RPC**: `http://<VM_PUBLIC_IP>:8550`
- **WebSocket**: `ws://<VM_PUBLIC_IP>:8546`  
- **P2P**: `<VM_PUBLIC_IP>:30310`

## Verification Commands

Check if nodes are connected:

```bash
# Check peer count (should show 3 peers when all nodes running)
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' \
  http://localhost:8550

# Check latest block number
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  http://localhost:8550

# Check node info
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"admin_nodeInfo","params":[],"id":1}' \
  http://localhost:8550
```

## Troubleshooting

### Common Issues

1. **Nodes not connecting**:
   - Verify firewall allows ports 30310, 8550, 8546, 30303
   - Check enode URLs are correct with proper IP addresses
   - Ensure all nodes use identical genesis.json

2. **Genesis file mismatch**:
   - All nodes must have identical genesis.json
   - Re-run init-blockchain.sh with correct validator addresses

3. **Bootstrap node not accessible**:
   - Verify VM1's public IP is reachable from other VMs
   - Check VM1's enode URL format is correct (should use port 30310)

4. **Permission errors**:
   ```bash
   chmod +x *.sh
   ```

### Viewing Logs

```bash
# View container logs
docker logs besu-node -f

# View Docker Compose logs  
docker compose logs -f
```

### Stopping Nodes

```bash
# Stop the node
docker compose down

# Stop and remove volumes (reset blockchain data)
docker compose down -v
```

## File Structure

After deployment:
```
besu/
├── DVRE-Node/
│   ├── data/
│   │   ├── key              # Private key
│   │   └── key.pub          # Public key
│   ├── genesis.json         # Blockchain genesis config
│   ├── node.address         # Node's validator address
│   ├── node.enode          # Node's enode URL (port 30310)
│   └── toEncode.json       # Validator list (temporary)
├── docker-compose.yml       # Generated by start scripts
├── generate-keys.sh         # Step 1: Generate node keys
├── init-blockchain.sh       # Step 2: Create genesis config
├── start-first-node.sh      # Step 3: Start bootstrap node
└── start-node.sh           # Step 4: Start and connect other nodes
```

## Security Notes

- Private keys are stored in `DVRE-Node/data/key` - keep secure
- Use proper firewall rules in production
- Consider VPN between VMs for additional security
- Monitor node access and rotate keys periodically

## Example Full Deployment

Assuming 4 VMs with these addresses after running generate-keys.sh:
- VM1: `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`
- VM2: `0x70997970C51812dc3A010C7d01b50e0d17dc79C8`  
- VM3: `0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC`
- VM4: `0x90F79bf6EB2c4f870365E785982E1f101E93b906`

Run init-blockchain.sh on each VM:
```bash
# VM1
./init-blockchain.sh 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC 0x90F79bf6EB2c4f870365E785982E1f101E93b906

# VM2  
./init-blockchain.sh 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC 0x90F79bf6EB2c4f870365E785982E1f101E93b906

# And so on...
```
