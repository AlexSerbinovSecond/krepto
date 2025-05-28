#!/bin/bash

# Krepto Adaptive Mining Script
# Automatically adjusts max_tries based on current difficulty
# Usage: ./mine_krepto_adaptive.sh [address] [blocks_per_batch]

# Default values
DEFAULT_ADDRESS="K7nRt8q9pqng1pDcNVYkYRM1w8WfDGYhXn"
DEFAULT_BLOCKS_PER_BATCH=1
BASE_MAX_TRIES=1000000  # Base tries for difficulty 1.0

# Get parameters
MINING_ADDRESS=${1:-$DEFAULT_ADDRESS}
BLOCKS_PER_BATCH=${2:-$DEFAULT_BLOCKS_PER_BATCH}

# Configuration
DATADIR="/Users/serbinov/.krepto"
RPC_PORT="12347"
CLI_CMD="./src/bitcoin-cli -datadir=$DATADIR -rpcport=$RPC_PORT"

echo "🚀 Starting Krepto Adaptive Mining"
echo "📍 Mining Address: $MINING_ADDRESS"
echo "🔢 Blocks per batch: $BLOCKS_PER_BATCH"
echo "🧠 Adaptive max_tries based on difficulty"
echo "⏰ Started at: $(date)"
echo "----------------------------------------"

# Function to calculate adaptive max_tries
calculate_max_tries() {
    local difficulty=$1
    
    # Get difficulty as a number (handle very small decimals)
    local diff_int=$(echo "$difficulty * 1000000" | bc -l | cut -d. -f1)
    
    # Calculate max_tries based on difficulty
    # Formula: base_tries * difficulty * safety_factor
    local safety_factor=10  # 10x safety margin
    local max_tries=$(echo "$BASE_MAX_TRIES * $difficulty * $safety_factor" | bc -l | cut -d. -f1)
    
    # Minimum 1M tries, maximum 100M tries
    if [[ $max_tries -lt 1000000 ]]; then
        max_tries=1000000
    elif [[ $max_tries -gt 100000000 ]]; then
        max_tries=100000000
    fi
    
    echo $max_tries
}

# Check if daemon is running
if ! $CLI_CMD getblockchaininfo > /dev/null 2>&1; then
    echo "❌ Error: Krepto daemon is not running!"
    echo "Start GUI with: ./src/qt/bitcoin-qt -datadir=$DATADIR"
    echo "Or start daemon with: ./src/bitcoind -datadir=$DATADIR -daemon"
    exit 1
fi

# Mining loop with adaptive difficulty
TOTAL_BLOCKS_MINED=0
START_TIME=$(date +%s)
ATTEMPT_COUNT=0
LAST_DIFFICULTY_CHECK=0

while true; do
    ATTEMPT_COUNT=$((ATTEMPT_COUNT + 1))
    
    # Check difficulty every 10 attempts or on first run
    CURRENT_TIME=$(date +%s)
    if [[ $((CURRENT_TIME - LAST_DIFFICULTY_CHECK)) -gt 60 ]] || [[ $ATTEMPT_COUNT -eq 1 ]]; then
        # Get current difficulty
        BLOCKCHAIN_INFO=$($CLI_CMD getblockchaininfo 2>/dev/null)
        CURRENT_DIFFICULTY=$(echo "$BLOCKCHAIN_INFO" | jq -r '.difficulty' 2>/dev/null || echo "0.001")
        CURRENT_HEIGHT=$(echo "$BLOCKCHAIN_INFO" | jq '.blocks' 2>/dev/null || echo "?")
        
        # Calculate adaptive max_tries
        MAX_TRIES=$(calculate_max_tries $CURRENT_DIFFICULTY)
        LAST_DIFFICULTY_CHECK=$CURRENT_TIME
        
        echo "📊 Difficulty Update:"
        echo "   Height: $CURRENT_HEIGHT"
        echo "   Difficulty: $CURRENT_DIFFICULTY"
        echo "   Adaptive max_tries: $MAX_TRIES"
        echo "----------------------------------------"
    fi
    
    echo "⛏️  Mining attempt #$ATTEMPT_COUNT - $BLOCKS_PER_BATCH block(s) (max_tries: $MAX_TRIES)..."
    
    # Mine blocks with adaptive max_tries
    RESULT=$($CLI_CMD generatetoaddress $BLOCKS_PER_BATCH $MINING_ADDRESS $MAX_TRIES 2>&1)
    
    if [[ $? -eq 0 ]]; then
        # Success - count blocks
        BLOCKS_MINED=$(echo "$RESULT" | jq '. | length' 2>/dev/null || echo "0")
        
        if [[ "$BLOCKS_MINED" -gt 0 ]]; then
            TOTAL_BLOCKS_MINED=$((TOTAL_BLOCKS_MINED + BLOCKS_MINED))
            
            # Get updated blockchain info
            BLOCKCHAIN_INFO=$($CLI_CMD getblockchaininfo 2>/dev/null)
            NEW_HEIGHT=$(echo "$BLOCKCHAIN_INFO" | jq '.blocks' 2>/dev/null || echo "?")
            BEST_HASH=$(echo "$BLOCKCHAIN_INFO" | jq -r '.bestblockhash' 2>/dev/null || echo "?")
            
            # Calculate mining rate
            CURRENT_TIME=$(date +%s)
            ELAPSED_TIME=$((CURRENT_TIME - START_TIME))
            if [[ $ELAPSED_TIME -gt 0 ]]; then
                BLOCKS_PER_HOUR=$(echo "scale=2; $TOTAL_BLOCKS_MINED * 3600 / $ELAPSED_TIME" | bc -l 2>/dev/null || echo "?")
            else
                BLOCKS_PER_HOUR="?"
            fi
            
            echo "✅ SUCCESS! Mined $BLOCKS_MINED block(s)! Height: $NEW_HEIGHT | Total mined: $TOTAL_BLOCKS_MINED | Rate: $BLOCKS_PER_HOUR blocks/hour"
            echo "🔗 Latest block: $BEST_HASH"
            
            # Show latest block hashes
            if [[ "$RESULT" != "[]" ]]; then
                echo "📦 New blocks:"
                echo "$RESULT" | jq -r '.[]' | while read hash; do
                    echo "   $hash"
                done
            fi
            
            # Force difficulty check on next iteration after finding blocks
            LAST_DIFFICULTY_CHECK=0
        else
            echo "⚠️  No blocks found in this attempt (tried $MAX_TRIES times) - continuing..."
        fi
    else
        echo "❌ Mining failed: $RESULT"
        echo "⏳ Waiting 2 seconds before retry..."
        sleep 2
    fi
    
    echo "📊 Attempts: $ATTEMPT_COUNT | Blocks found: $TOTAL_BLOCKS_MINED | Difficulty: $CURRENT_DIFFICULTY"
    echo "----------------------------------------"
    
    # Very small delay between attempts
    sleep 0.5
done 