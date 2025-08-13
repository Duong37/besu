#!/bin/bash

# Besu Bootstrap Node Startup Script
# Usage: ./start-first-node.sh
# This script starts the first node that other nodes will connect to
# Must run generate-keys.sh and init-blockchain.sh first

set -e

echo "Starting Besu bootstrap node..."

# Check if genesis.json exists
if [ ! -f "DVRE-Node/genesis.json" ]; then
    echo "Error: genesis.json not found in DVRE-Node directory"
    echo "Run ./init-blockchain.sh first to create the genesis configuration"
    exit 1
fi

# Check if node keys exist
if [ ! -f "DVRE-Node/data/key" ]; then
    echo "Error: Node keys not found"
    echo "Run ./generate-keys.sh first to generate node keys"
    exit 1
fi

# Fetch public IP
PUBLIC_IP=$(curl -s https://api.ipify.org)
if [ -z "$PUBLIC_IP" ]; then
    echo "Error: Could not fetch public IP"
    exit 1
fi

echo "Starting Besu bootstrap node with public IP: $PUBLIC_IP"

# Display this node's enode for other nodes to use
if [ -f "DVRE-Node/node.enode" ]; then
    echo "Bootstrap node enode (share this with other nodes):"
    cat DVRE-Node/node.enode
    echo ""
fi

# Create docker-compose.yml for bootstrap node (without bootnodes line)
cat > docker-compose.yml << EOF
services:
  besu-node:
    image: hyperledger/besu:latest
    container_name: besu-node
    ports:
      - "8546:8546"      # WebSocket JSON-RPC
      - "8550:8550"      # HTTP JSON-RPC
      - "30310:30310/tcp"  # P2P TCP
      - "30310:30310/udp"  # P2P UDP
      - "30303:30303"      # Bootnode port
    volumes:
      - ./DVRE-Node/data:/opt/besu/data
      - ./DVRE-Node/genesis.json:/opt/besu/genesis.json
    command: >
      --data-path=/opt/besu/data
      --genesis-file=/opt/besu/genesis.json
      --p2p-port=30310
      --rpc-http-port=8550
      --p2p-host=$PUBLIC_IP
      --rpc-http-host=0.0.0.0
      --rpc-http-enabled
      --rpc-http-api=ETH,NET,IBFT
      --rpc-ws-enabled
      --rpc-ws-host=0.0.0.0
      --rpc-ws-port=8546
      --rpc-ws-api=ETH,NET,WEB3
      --host-allowlist="*"
      --rpc-http-cors-origins="all"
      --profile=ENTERPRISE
      --min-gas-price=0

EOF

echo "Docker Compose file created for bootstrap node"

# Stop any existing containers
echo "Stopping any existing Besu containers..."
docker compose down 2>/dev/null || true

# Start the bootstrap node
echo "Starting Besu bootstrap node..."
echo "RPC endpoint will be available at: http://$PUBLIC_IP:8550"
echo "WebSocket endpoint will be available at: ws://$PUBLIC_IP:8546"
echo ""
echo "Press Ctrl+C to stop the node"

docker compose up -d