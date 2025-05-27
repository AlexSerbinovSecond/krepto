#!/bin/bash

echo "🚀 Starting Krepto GUI"
echo "======================"

# Stop all processes first
echo "🛑 Stopping existing processes..."
./scripts/stop_all.sh

# Wait a moment
sleep 2

# Check if GUI binary exists
if [ ! -f "src/qt/bitcoin-qt" ]; then
    echo "❌ GUI binary not found. Please build the project first:"
    echo "   ./scripts/rebuild_and_start.sh"
    exit 1
fi

# Start GUI
echo "🖥️  Starting Krepto GUI..."
echo "💡 Choose startup mode:"
echo "1) Mainnet (real data)"
echo "2) Testnet (safe testing)"
echo ""
read -p "Enter choice (1 or 2, default: 1): " choice

case $choice in
    2)
        echo "🧪 Starting in testnet mode..."
        mkdir -p /tmp/krepto-test
        chmod 755 /tmp/krepto-test
        ./src/qt/bitcoin-qt -testnet -datadir="/tmp/krepto-test" &
        ;;
    *)
        echo "🌐 Starting in mainnet mode..."
        ./src/qt/bitcoin-qt -datadir="/Users/serbinov/.krepto" &
        ;;
esac

GUI_PID=$!
echo "✅ GUI started with PID: $GUI_PID"
echo ""
echo "📋 Useful commands:"
echo "   Stop GUI: kill $GUI_PID"
echo "   Stop all: ./scripts/stop_all.sh"
echo "   Rebuild:  ./scripts/rebuild_and_start.sh"
echo "" 