#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "Generating node keys using Docker..."

# Clean up any existing data and create fresh directory
rm -rf DVRE-Node/data
mkdir -p DVRE-Node/data

# Generate the node key pair using Docker
# First generate the private key, then export the public key
echo "Generating private key..."
docker run --rm \
    -v "$(pwd)/DVRE-Node/data:/opt/besu/data" \
    hyperledger/besu:latest \
    --data-path=/opt/besu/data public-key generate

echo "Exporting public key..."
docker run --rm \
    -v "$(pwd)/DVRE-Node/data:/opt/besu/data" \
    hyperledger/besu:latest \
    --data-path=/opt/besu/data public-key export --to=/opt/besu/data/key.pub

echo "Node key pair generated and stored in DVRE-Node/data"

# Export the node address using Docker
NODE_ADDRESS=$(docker run --rm \
    -v "$(pwd)/DVRE-Node/data:/opt/besu/data" \
    hyperledger/besu:latest \
    --data-path=/opt/besu/data public-key export-address --node-private-key-file=/opt/besu/data/key)

echo "Node address: $NODE_ADDRESS"
echo "$NODE_ADDRESS" > DVRE-Node/node.address

# Get public IP for enode
PUBLIC_IP=$(curl -s https://api.ipify.org)
if [ -z "$PUBLIC_IP" ]; then
    echo "Warning: Could not fetch public IP"
    PUBLIC_IP="YOUR_PUBLIC_IP"
fi

# Create enode URL (using port 30310 for P2P)
ENODE="enode://$(cat DVRE-Node/data/key.pub)@${PUBLIC_IP}:30310"
echo "Node enode: $ENODE"
echo "$ENODE" > DVRE-Node/node.enode

echo "Generated files:"
echo "  - Private key: DVRE-Node/data/key"
echo "  - Public key: DVRE-Node/data/key.pub" 
echo "  - Node address: DVRE-Node/node.address"
echo "  - Node enode: DVRE-Node/node.enode"
