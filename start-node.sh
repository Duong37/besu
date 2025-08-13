#!/bin/bash

# Besu Node Startup Script
# Usage: ./start-node.sh <bootstrap_enode>
# This script starts a non-bootstrap node and connects it to the network
# Must run generate-keys.sh first and have the same genesis.json as other nodes

set -e

# Check if enode URL is provided
if [ $# -eq 0 ]; then
    echo "Error: No bootstrap enode URL provided"
    echo "Usage: $0 <bootstrap_enode>"
    echo "Example: $0 enode://abcd1234...@192.168.1.100:30310"
    echo ""
    echo "Get the bootstrap enode from the first node's DVRE-Node/node.enode file"
    exit 1
fi

BOOTSTRAP_ENODE="$1"

echo "Starting Besu node with bootstrap: $BOOTSTRAP_ENODE"

# Check if genesis.json exists
if [ ! -f "DVRE-Node/genesis.json" ]; then
    echo "Error: genesis.json not found in DVRE-Node directory"
    echo "Copy the genesis.json from the bootstrap node to this location"
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

echo "Starting Besu node with public IP: $PUBLIC_IP"

# Display this node's enode 
if [ -f "DVRE-Node/node.enode" ]; then
    echo "This node's enode:"
    cat DVRE-Node/node.enode
    echo ""
fi

# Create docker-compose.yml with the provided bootstrap enode
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
      --bootnodes=$BOOTSTRAP_ENODE
      --p2p-port=30310
      --rpc-http-port=8550
      --p2p-host=$PUBLIC_IP
      --rpc-http-host=0.0.0.0
      --rpc-http-enabled
      --rpc-http-api=ETH,NET,IBFT,ADMIN
      --rpc-ws-enabled
      --rpc-ws-host=0.0.0.0
      --rpc-ws-port=8546
      --rpc-ws-api=ETH,NET,WEB3,ADMIN
      --host-allowlist="*"
      --rpc-http-cors-origins="all"
      --profile=ENTERPRISE
      --min-gas-price=0

EOF

echo "Docker Compose file created with bootstrap node: $BOOTSTRAP_ENODE"

# Stop any existing containers
echo "Stopping any existing Besu containers..."
docker compose down 2>/dev/null || true

# Start the node
echo "Starting Besu node..."
echo "RPC endpoint will be available at: http://$PUBLIC_IP:8550"
echo "WebSocket endpoint will be available at: ws://$PUBLIC_IP:8546"
echo ""
echo "Press Ctrl+C to stop the node"

docker compose up -d