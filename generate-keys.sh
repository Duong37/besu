#!/bin/bash
set -e

mkdir -p DVRE-Node/data

# Generate the node key pair (this will create key + key.pub if not existing)
sudo docker run --rm \
  -u $(id -u):$(id -g) \
  -v "$PWD/DVRE-Node/data:/opt/besu/data" \
  hyperledger/besu:latest \
  --data-path=/opt/besu/data public-key export --to=/opt/besu/data/key.pub

echo "Node key pair generated and stored in DVRE-Node/data"

# Export the node address
sudo docker run --rm \
  -u $(id -u):$(id -g) \
  -v "$PWD/DVRE-Node/data:/opt/besu/data" \
  hyperledger/besu:latest \
  public-key export-address \
  --node-private-key-file=/opt/besu/data/key
