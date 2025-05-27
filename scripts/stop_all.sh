#!/bin/bash

echo "🛑 Stopping All Krepto Processes"
echo "================================="

# Stop daemon gracefully if running
echo "📡 Stopping Krepto daemon..."
if ./src/bitcoin-cli -datadir="/Users/serbinov/.krepto" stop 2>/dev/null; then
    echo "✅ Daemon stopped gracefully"
    sleep 2
else
    echo "ℹ️  Daemon was not running or already stopped"
fi

# Kill any remaining processes
echo "🔍 Checking for remaining processes..."
PROCESSES=$(ps aux | grep -E "(bitcoind|bitcoin-qt|mine_)" | grep -v grep | awk '{print $2}')

if [ -n "$PROCESSES" ]; then
    echo "🔪 Killing remaining processes: $PROCESSES"
    echo "$PROCESSES" | xargs kill -9 2>/dev/null
    sleep 1
    
    # Double check
    REMAINING=$(ps aux | grep -E "(bitcoind|bitcoin-qt|mine_)" | grep -v grep | awk '{print $2}')
    if [ -n "$REMAINING" ]; then
        echo "⚠️  Some processes still running: $REMAINING"
        echo "$REMAINING" | xargs kill -9 2>/dev/null
    else
        echo "✅ All processes stopped"
    fi
else
    echo "✅ No processes found"
fi

# Stop mining scripts
echo "⛏️  Stopping mining scripts..."
pkill -f mine_to_retarget.sh 2>/dev/null
pkill -f mine_krepto.sh 2>/dev/null

echo "🎉 All Krepto processes stopped!"
echo ""
