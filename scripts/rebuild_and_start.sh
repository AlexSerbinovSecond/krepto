#!/bin/bash

echo "🔨 Rebuild and Start Krepto GUI"
echo "==============================="

# Stop all processes first
echo "🛑 Stopping existing processes..."
./scripts/stop_all.sh

# Wait a moment
sleep 2

echo "🔧 Starting rebuild process..."
echo ""

# Try incremental build first (faster)
echo "⚡ Attempting incremental build..."
if make -j8 src/qt/bitcoin-qt 2>/dev/null; then
    echo "✅ Incremental build successful!"
    BUILD_SUCCESS=true
else
    echo "⚠️  Incremental build failed, trying full rebuild..."
    BUILD_SUCCESS=false
fi

# If incremental build failed, do full rebuild
if [ "$BUILD_SUCCESS" = false ]; then
    echo "🔄 Performing full rebuild..."
    
    # Clean and rebuild
    make clean
    
    echo "🔧 Running autogen..."
    ./autogen.sh
    
    echo "🔧 Running configure..."
    ./configure --disable-tests --disable-bench --with-gui=qt5
    
    echo "🔨 Building project (this may take a while)..."
    if make -j8; then
        echo "✅ Full rebuild successful!"
        BUILD_SUCCESS=true
    else
        echo "❌ Build failed!"
        echo "Please check the error messages above."
        exit 1
    fi
fi

# Check if GUI binary exists
if [ ! -f "src/qt/bitcoin-qt" ]; then
    echo "❌ GUI binary not found after build!"
    exit 1
fi

echo ""
echo "🖥️  Starting Krepto GUI..."
echo "💡 Choose startup mode:"
echo "1) Mainnet (real data)"
echo "2) Testnet (safe testing)"
echo ""
read -p "Enter choice (1 or 2, default: 2 for testing): " choice

case $choice in
    1)
        echo "🌐 Starting in mainnet mode..."
        ./src/qt/bitcoin-qt -datadir="/Users/serbinov/.krepto" &
        ;;
    *)
        echo "🧪 Starting in testnet mode (recommended for testing)..."
        mkdir -p /tmp/krepto-test
        chmod 755 /tmp/krepto-test
        ./src/qt/bitcoin-qt -testnet -datadir="/tmp/krepto-test" &
        ;;
esac

GUI_PID=$!
echo "✅ GUI started with PID: $GUI_PID"
echo ""
echo "🎉 Rebuild and start completed successfully!"
echo ""
echo "📋 Useful commands:"
echo "   Stop GUI: kill $GUI_PID"
echo "   Stop all: ./scripts/stop_all.sh"
echo "   View logs: tail -f debug.log"
echo "" 