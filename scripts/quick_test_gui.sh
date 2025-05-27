#!/bin/bash

echo "🚀 Quick GUI Test Script"
echo "========================"

# Stop existing processes
echo "🛑 Stopping existing processes..."
./scripts/stop_all.sh

# Wait a moment
sleep 1

# Check if GUI binary exists
if [ ! -f "src/qt/bitcoin-qt" ]; then
    echo "❌ GUI binary not found. Building..."
    
    # Try quick build first
    if make -j8 src/qt/bitcoin-qt; then
        echo "✅ Quick build successful!"
    else
        echo "❌ Quick build failed. Try full rebuild:"
        echo "   ./scripts/rebuild_and_start.sh"
        exit 1
    fi
fi

echo "🔧 Starting Krepto GUI in test mode..."
echo "🧪 Using testnet mode for safe testing..."

# Create test directory if it does not exist
echo "📁 Creating test directory..."
mkdir -p /tmp/krepto-test
chmod 755 /tmp/krepto-test

# Start GUI in testnet mode
echo "🚀 Launching GUI..."
./src/qt/bitcoin-qt -testnet -datadir="/tmp/krepto-test" &
GUI_PID=$!

echo "✅ GUI started in testnet mode with PID: $GUI_PID"
echo ""
echo "🧪 Test Environment Info:"
echo "   Mode: Testnet (safe for testing)"
echo "   Data: /tmp/krepto-test (temporary)"
echo "   PID:  $GUI_PID"
echo ""
echo "🔍 What to check:"
echo "   ✓ All 'Bitcoin' text changed to 'Krepto'"
echo "   ✓ All 'BTC' symbols changed to 'KREPTO'"
echo "   ✓ Mining buttons are active"
echo "   ✓ Currency units display correctly"
echo ""
echo "📋 Useful commands:"
echo "   Stop GUI:     kill $GUI_PID"
echo "   Stop all:     ./scripts/stop_all.sh"
echo "   Full rebuild: ./scripts/rebuild_and_start.sh"
echo "   Mainnet GUI:  ./scripts/start_gui.sh"
echo ""
