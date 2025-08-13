#!/bin/bash

# This script initializes a Besu blockchain
# A genesis file will be created for all 4 validator nodes
# Usage: ./init-blockchain.sh <validator_address_2> <validator_address_3> <validator_address_4>
# The first validator address comes from the current node's generated keys

set -e

# Check if three arguments are provided (addresses for nodes 2, 3, 4)
if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <validator_address_2> <validator_address_3> <validator_address_4>"
  echo "Example: $0 0x1234... 0x5678... 0x9abc..."
  echo ""
  echo "Steps to get validator addresses:"
  echo "1. Run ./generate-keys.sh on all 4 VMs"
  echo "2. Collect the node addresses from DVRE-Node/node.address on each VM"
  echo "3. Run this script on each VM with the other 3 addresses"
  exit 1
fi

# Assign arguments to variables
VALIDATOR_ADDRESS_2=$1
VALIDATOR_ADDRESS_3=$2
VALIDATOR_ADDRESS_4=$3

# Ensure keys are generated first
if [ ! -f "DVRE-Node/data/key" ]; then
    echo "Error: Node keys not found. Run ./generate-keys.sh first"
    exit 1
fi

mkdir -p DVRE-Node

# Get this node's validator address
VALIDATOR_ADDRESS_1=$(cat DVRE-Node/node.address)
echo "Node 1 address (this node): $VALIDATOR_ADDRESS_1"
echo "Node 2 address: $VALIDATOR_ADDRESS_2"
echo "Node 3 address: $VALIDATOR_ADDRESS_3"
echo "Node 4 address: $VALIDATOR_ADDRESS_4"

# Create JSON array for RLP encoding (remove 0x prefix)
cat > DVRE-Node/toEncode.json <<EOL
["${VALIDATOR_ADDRESS_1:2}", "${VALIDATOR_ADDRESS_2:2}", "${VALIDATOR_ADDRESS_3:2}", "${VALIDATOR_ADDRESS_4:2}"]
EOL

# Use Docker to RLP encode the validator list
echo "Encoding validator list..."
ENCODED_VALIDATORS=$(docker run --rm \
    -v "$(pwd)/DVRE-Node:/data" \
    hyperledger/besu:latest \
    rlp encode --from=/data/toEncode.json)

echo "Encoded validators: $ENCODED_VALIDATORS"

# Create genesis.json
cat > DVRE-Node/genesis.json <<EOL
{
  "config" : {
    "chainId" : 1337,
    "berlinBlock" : 0,
    "londonBlock" : 0,
    "ibft2" : {
      "blockperiodseconds" : 2,
      "epochlength" : 30000,
      "requesttimeoutseconds" : 4
    }
  },
  "nonce" : "0x0",
  "timestamp" : "0x58ee40ba",
  "gasLimit" : "0x1fffffffffffff",
  "difficulty" : "0x1",
  "mixHash" : "0x63746963616c2062797a616e74696e65206661756c7420746f6c6572616e6365",
  "coinbase" : "0x0000000000000000000000000000000000000000",
  "extraData" : "$ENCODED_VALIDATORS",
  "alloc": {
    "$VALIDATOR_ADDRESS_1": {
      "balance": "0x200000000000000000000000000000000000000000000000000000000000000"
    },
    "$VALIDATOR_ADDRESS_2": {
      "balance": "0x200000000000000000000000000000000000000000000000000000000000000"
    },
    "$VALIDATOR_ADDRESS_3": {
      "balance": "0x200000000000000000000000000000000000000000000000000000000000000"
    },
    "$VALIDATOR_ADDRESS_4": {
      "balance": "0x200000000000000000000000000000000000000000000000000000000000000"
    }
  }
}
EOL

echo "Genesis file created successfully in DVRE-Node/genesis.json"
echo "All 4 nodes must use this SAME genesis.json file"
echo ""
echo "Next steps:"
echo "1. Copy this genesis.json to all other VMs (must be identical)"
echo "2. Use ./start-first-node.sh on the first node"
echo "3. Use ./start-node.sh <enode> on other nodes"