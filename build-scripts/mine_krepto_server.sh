#!/bin/bash

# Krepto Server Mining Script
# Usage: ./mine_krepto_server.sh [address] [blocks_per_batch]

# Default values
DEFAULT_ADDRESS="kr1qluy944vt4yhwlcdnxa8avvenaklydh6zmtcnm6"
DEFAULT_BLOCKS_PER_BATCH=1
DEFAULT_MAX_TRIES=10000000

# Get parameters
MINING_ADDRESS=${1:-$DEFAULT_ADDRESS}
BLOCKS_PER_BATCH=${2:-$DEFAULT_BLOCKS_PER_BATCH}
MAX_TRIES=${3:-$DEFAULT_MAX_TRIES}

# Configuration for server
DATADIR="/root/.krepto"
RPC_PORT="12347"
CLI_CMD="./src/bitcoin-cli -datadir=$DATADIR -rpcport=$RPC_PORT"

echo "🚀 Starting Krepto Server Mining"
echo "📍 Mining Address: $MINING_ADDRESS"
echo "🔢 Blocks per batch: $BLOCKS_PER_BATCH"
echo "🎯 Max tries per block: $MAX_TRIES"
echo "⏰ Started at: $(date)"
echo "🌐 Server IP: 164.68.117.90"
echo "----------------------------------------"

# Check if daemon is running
if ! $CLI_CMD getblockchaininfo > /dev/null 2>&1; then
    echo "❌ Error: Krepto daemon is not running!"
    echo "Start it with: ./src/bitcoind -datadir=$DATADIR -daemon"
    exit 1
fi

# Mining loop
TOTAL_BLOCKS_MINED=0
START_TIME=$(date +%s)

while true; do
    echo "⛏️  Mining $BLOCKS_PER_BATCH block(s)..."
    
    # Add randomization like in GUI
    RANDOM_DELAY=$((RANDOM % 10 + 5))  # 5-15 seconds
    RANDOM_TRIES=$((500000 + RANDOM % 1500000))  # 500K-2M tries
    
    echo "🎲 Using randomized parameters: tries=$RANDOM_TRIES, delay=${RANDOM_DELAY}s"
    sleep $RANDOM_DELAY
    
    # Mine blocks
    RESULT=$($CLI_CMD generatetoaddress $BLOCKS_PER_BATCH $MINING_ADDRESS $RANDOM_TRIES 2>&1)
    
    if [[ $? -eq 0 ]]; then
        # Success - count blocks
        BLOCKS_MINED=$(echo "$RESULT" | grep -o '"[^"]*"' | wc -l 2>/dev/null || echo "0")
        if [[ "$RESULT" == "[]" ]]; then
            BLOCKS_MINED=0
        fi
        
        TOTAL_BLOCKS_MINED=$((TOTAL_BLOCKS_MINED + BLOCKS_MINED))
        
        # Get current blockchain info
        BLOCKCHAIN_INFO=$($CLI_CMD getblockchaininfo 2>/dev/null)
        CURRENT_HEIGHT=$(echo "$BLOCKCHAIN_INFO" | grep '"blocks"' | grep -o '[0-9]*' || echo "?")
        BEST_HASH=$(echo "$BLOCKCHAIN_INFO" | grep '"bestblockhash"' | cut -d'"' -f4 || echo "?")
        
        # Calculate mining rate
        CURRENT_TIME=$(date +%s)
        ELAPSED_TIME=$((CURRENT_TIME - START_TIME))
        if [[ $ELAPSED_TIME -gt 0 ]]; then
            BLOCKS_PER_HOUR=$((TOTAL_BLOCKS_MINED * 3600 / ELAPSED_TIME))
        else
            BLOCKS_PER_HOUR="?"
        fi
        
        if [[ $BLOCKS_MINED -gt 0 ]]; then
            echo "✅ SUCCESS! Mined $BLOCKS_MINED block(s)! Height: $CURRENT_HEIGHT | Total: $TOTAL_BLOCKS_MINED | Rate: $BLOCKS_PER_HOUR blocks/hour"
            echo "🔗 Latest block: $BEST_HASH"
            echo "$RESULT"
        else
            echo "⏳ No blocks found this round. Height: $CURRENT_HEIGHT"
        fi
    else
        echo "❌ Mining failed: $RESULT"
        echo "⏳ Waiting 10 seconds before retry..."
        sleep 10
    fi
    
    echo "----------------------------------------"
    
    # Small delay between batches
    sleep 2
done 