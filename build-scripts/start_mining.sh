#!/bin/bash

# Simple Krepto Mining Starter
# This script helps users start mining Krepto easily

echo "🚀 Krepto Mining Setup"
echo "======================"

# Check if bitcoind is running
if ! ./src/bitcoin-cli -datadir=/Users/serbinov/.krepto -rpcport=12347 getblockchaininfo > /dev/null 2>&1; then
    echo "❌ Krepto daemon is not running!"
    echo "Starting Krepto daemon..."
    ./src/bitcoind -datadir=/Users/serbinov/.krepto -daemon
    echo "⏳ Waiting for daemon to start..."
    sleep 5
fi

# Get or create mining address
echo "💰 Setting up mining address..."
MINING_ADDRESS=$(./src/bitcoin-cli -datadir=/Users/serbinov/.krepto -rpcport=12347 getnewaddress "mining" 2>/dev/null)

if [[ -z "$MINING_ADDRESS" ]]; then
    echo "❌ Failed to get mining address. Make sure wallet is loaded."
    echo "Creating new wallet..."
    ./src/bitcoin-cli -datadir=/Users/serbinov/.krepto -rpcport=12347 createwallet "mining_wallet" > /dev/null 2>&1
    MINING_ADDRESS=$(./src/bitcoin-cli -datadir=/Users/serbinov/.krepto -rpcport=12347 getnewaddress "mining")
fi

echo "📍 Mining address: $MINING_ADDRESS"

# Show current status
echo ""
echo "📊 Current Krepto Network Status:"
BLOCKCHAIN_INFO=$(./src/bitcoin-cli -datadir=/Users/serbinov/.krepto -rpcport=12347 getblockchaininfo)
BLOCKS=$(echo "$BLOCKCHAIN_INFO" | jq '.blocks')
DIFFICULTY=$(echo "$BLOCKCHAIN_INFO" | jq '.difficulty')
echo "   Blocks: $BLOCKS"
echo "   Difficulty: $DIFFICULTY"

# Ask user what they want to do
echo ""
echo "What would you like to do?"
echo "1) Start continuous mining (recommended)"
echo "2) Mine a specific number of blocks"
echo "3) Just mine 1 block to test"
echo "4) Exit"
echo ""
read -p "Choose option (1-4): " choice

case $choice in
    1)
        echo "🚀 Starting continuous mining..."
        echo "Press Ctrl+C to stop mining"
        ./mine_krepto.sh "$MINING_ADDRESS"
        ;;
    2)
        read -p "How many blocks to mine? " num_blocks
        echo "⛏️  Mining $num_blocks blocks..."
        ./src/bitcoin-cli -datadir=/Users/serbinov/.krepto -rpcport=12347 generatetoaddress "$num_blocks" "$MINING_ADDRESS" 10000000
        ;;
    3)
        echo "⛏️  Mining 1 test block..."
        ./src/bitcoin-cli -datadir=/Users/serbinov/.krepto -rpcport=12347 generatetoaddress 1 "$MINING_ADDRESS" 10000000
        ;;
    4)
        echo "👋 Goodbye!"
        exit 0
        ;;
    *)
        echo "❌ Invalid option"
        exit 1
        ;;
esac

echo ""
echo "✅ Mining completed!"
echo "💰 Check your balance with:"
echo "   ./src/bitcoin-cli -datadir=/Users/serbinov/.krepto -rpcport=12347 getbalance" 