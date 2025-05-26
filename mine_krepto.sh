#!/bin/bash

# Krepto Continuous Mining Script
# Usage: ./mine_krepto.sh [address] [blocks_per_batch]

# Default values
DEFAULT_ADDRESS="kr1qyd9fkjjacagwha4l4548q02glxt9w88rxpuyr3"
DEFAULT_BLOCKS_PER_BATCH=1
DEFAULT_MAX_TRIES=10000000

# Get parameters
MINING_ADDRESS=${1:-$DEFAULT_ADDRESS}
BLOCKS_PER_BATCH=${2:-$DEFAULT_BLOCKS_PER_BATCH}
MAX_TRIES=${3:-$DEFAULT_MAX_TRIES}

# Configuration
DATADIR="/Users/serbinov/.krepto"
RPC_PORT="12347"
CLI_CMD="./src/bitcoin-cli -datadir=$DATADIR -rpcport=$RPC_PORT"

echo "🚀 Starting Krepto Continuous Mining"
echo "📍 Mining Address: $MINING_ADDRESS"
echo "🔢 Blocks per batch: $BLOCKS_PER_BATCH"
echo "🎯 Max tries per block: $MAX_TRIES"
echo "⏰ Started at: $(date)"
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
    
    # Mine blocks
    RESULT=$($CLI_CMD generatetoaddress $BLOCKS_PER_BATCH $MINING_ADDRESS $MAX_TRIES 2>&1)
    
    if [[ $? -eq 0 ]]; then
        # Success - count blocks
        BLOCKS_MINED=$(echo "$RESULT" | jq '. | length' 2>/dev/null || echo "0")
        TOTAL_BLOCKS_MINED=$((TOTAL_BLOCKS_MINED + BLOCKS_MINED))
        
        # Get current blockchain info
        BLOCKCHAIN_INFO=$($CLI_CMD getblockchaininfo 2>/dev/null)
        CURRENT_HEIGHT=$(echo "$BLOCKCHAIN_INFO" | jq '.blocks' 2>/dev/null || echo "?")
        BEST_HASH=$(echo "$BLOCKCHAIN_INFO" | jq -r '.bestblockhash' 2>/dev/null || echo "?")
        
        # Calculate mining rate
        CURRENT_TIME=$(date +%s)
        ELAPSED_TIME=$((CURRENT_TIME - START_TIME))
        if [[ $ELAPSED_TIME -gt 0 ]]; then
            BLOCKS_PER_HOUR=$(echo "scale=2; $TOTAL_BLOCKS_MINED * 3600 / $ELAPSED_TIME" | bc -l 2>/dev/null || echo "?")
        else
            BLOCKS_PER_HOUR="?"
        fi
        
        echo "✅ Mined $BLOCKS_MINED block(s)! Height: $CURRENT_HEIGHT | Total mined: $TOTAL_BLOCKS_MINED | Rate: $BLOCKS_PER_HOUR blocks/hour"
        echo "🔗 Latest block: $BEST_HASH"
        
        # Show latest block hashes
        if [[ "$RESULT" != "[]" ]]; then
            echo "📦 New blocks:"
            echo "$RESULT" | jq -r '.[]' | while read hash; do
                echo "   $hash"
            done
        fi
    else
        echo "❌ Mining failed: $RESULT"
        echo "⏳ Waiting 5 seconds before retry..."
        sleep 5
    fi
    
    echo "----------------------------------------"
    
    # Small delay between batches
    sleep 1
done 