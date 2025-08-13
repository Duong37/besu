# Besu 4-Node Network - Quick Deployment

## Prerequisites
- Docker and Docker Compose installed on all 4 VMs
- Ports 8550, 8546, 30310, 30303 open in firewall

## Step 1: Setup on All VMs

```bash
git clone <this-repo>
cd besu
chmod +x *.sh
```

## Step 2: Generate Keys (Run on Each VM)

```bash
./generate-keys.sh
cat DVRE-Node/node.address
```
**Copy the address output - you need all 4 addresses**

## Step 3: Collect All Node Addresses

After running Step 2 on all VMs, you should have:
- VM1 Address: `0x...`
- VM2 Address: `0x...` 
- VM3 Address: `0x...`
- VM4 Address: `0x...`

## Step 4: Initialize Genesis (Run on Each VM)

**VM1:**
```bash
./init-blockchain.sh <VM2_ADDRESS> <VM3_ADDRESS> <VM4_ADDRESS>
```

**VM2:**
```bash
./init-blockchain.sh <VM1_ADDRESS> <VM3_ADDRESS> <VM4_ADDRESS>
```

**VM3:**
```bash
./init-blockchain.sh <VM1_ADDRESS> <VM2_ADDRESS> <VM4_ADDRESS>
```

**VM4:**
```bash
./init-blockchain.sh <VM1_ADDRESS> <VM2_ADDRESS> <VM3_ADDRESS>
```

## Step 5: Start Bootstrap Node (VM1 Only)

```bash
./start-first-node.sh
```

**Copy the enode output** - looks like:
`enode://abc123...@IP:30310`

## Step 6: Start Other Nodes (VM2, VM3, VM4)

**VM2:**
```bash
./start-node.sh <BOOTSTRAP_ENODE_FROM_VM1>
```

**VM3:**
```bash
./start-node.sh <BOOTSTRAP_ENODE_FROM_VM1>
```

**VM4:**
```bash
./start-node.sh <BOOTSTRAP_ENODE_FROM_VM1>
```

## Verify Network

Check peer connections (run on any VM):
```bash
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' \
  http://localhost:8550
```

Should return `"result":"0x3"` (3 peers)

## Stop Nodes

```bash
docker compose down
```

## Reset (if needed)

```bash
docker compose down -v
rm -rf DVRE-Node/
``` 