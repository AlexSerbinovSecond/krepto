#!/bin/bash

# Quick test script for Krepto GUI with mining
echo "Starting Krepto GUI for testing..."

# Kill any existing instances
pkill -f bitcoin-qt
pkill -f bitcoind

# Wait a moment
sleep 2

# Start the GUI
./src/qt/bitcoin-qt -datadir=/Users/serbinov/.krepto -rpcport=12347 -port=12345 &

echo "Krepto GUI started in background"
echo "Check the Mining menu for Start Mining, Stop Mining, and Mining Console options"
echo "To stop: pkill -f bitcoin-qt"
