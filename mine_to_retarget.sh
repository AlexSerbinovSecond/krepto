#!/bin/bash

# Mine to first difficulty retarget (block 2016)
# This will demonstrate automatic difficulty adjustment

DATADIR="/Users/serbinov/.krepto"
ADDRESS="kr1qyd9fkjjacagwha4l4548q02glxt9w88rxpuyr3"
TARGET_BLOCK=2016

echo "🎯 Mining to first difficulty retarget at block $TARGET_BLOCK"
echo "📍 Mining Address: $ADDRESS"
echo "⏰ Started at: $(date)"
echo "----------------------------------------"

while true; do
    # Get current block height
    CURRENT_HEIGHT=$(./src/bitcoin-cli -datadir="$DATADIR" getblockcount 2>/dev/null)
    
    if [ $? -ne 0 ]; then
        echo "❌ Error: Cannot connect to Krepto daemon"
        exit 1
    fi
    
    if [ "$CURRENT_HEIGHT" -ge "$TARGET_BLOCK" ]; then
        echo "🎉 Reached target block $TARGET_BLOCK!"
        echo "📊 Getting difficulty info..."
        ./src/bitcoin-cli -datadir="$DATADIR" getmininginfo
        break
    fi
    
    REMAINING=$((TARGET_BLOCK - CURRENT_HEIGHT))
    
    # Mine in batches of 100 blocks for faster progress
    BATCH_SIZE=100
    if [ "$REMAINING" -lt "$BATCH_SIZE" ]; then
        BATCH_SIZE=$REMAINING
    fi
    
    echo "⛏️  Mining $BATCH_SIZE blocks... (Current: $CURRENT_HEIGHT, Remaining: $REMAINING)"
    
    # Mine batch with high max_tries for reliability
    RESULT=$(./src/bitcoin-cli -datadir="$DATADIR" generatetoaddress $BATCH_SIZE "$ADDRESS" 10000000 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        NEW_HEIGHT=$(./src/bitcoin-cli -datadir="$DATADIR" getblockcount 2>/dev/null)
        echo "✅ Mined $BATCH_SIZE blocks! New height: $NEW_HEIGHT"
        
        # Show progress every 500 blocks
        if [ $((NEW_HEIGHT % 500)) -eq 0 ]; then
            echo "📈 Progress: $NEW_HEIGHT/$TARGET_BLOCK blocks ($(( (NEW_HEIGHT * 100) / TARGET_BLOCK ))%)"
            ./src/bitcoin-cli -datadir="$DATADIR" getmininginfo | grep -E '"difficulty"|"networkhashps"'
        fi
    else
        echo "❌ Mining failed, retrying..."
        sleep 1
    fi
done

echo "----------------------------------------"
echo "🏁 Mining to retarget completed!"
echo "📊 Final blockchain info:"
./src/bitcoin-cli -datadir="$DATADIR" getblockchaininfo 