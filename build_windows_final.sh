#!/bin/bash

set -e

echo "🪟 Building Krepto Windows Final Version..."

# Перевірити наявність mingw
if ! command -v x86_64-w64-mingw32-g++ &> /dev/null; then
    echo "❌ mingw-w64 not found. Installing..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install mingw-w64
    else
        echo "Please install mingw-w64 manually"
        exit 1
    fi
fi

echo "✅ mingw-w64 found: $(x86_64-w64-mingw32-g++ --version | head -1)"

# Очистити попередню збірку
echo "🧹 Cleaning previous build..."
make clean 2>/dev/null || true

# Збудувати тільки необхідні залежності (без Qt)
echo "📦 Building dependencies (without Qt)..."
cd depends
make HOST=x86_64-w64-mingw32 -j8 \
    NO_UPNP=1 \
    NO_NATPMP=1 \
    NO_ZMQ=1 \
    NO_QT=1 \
    NO_USDT=1
cd ..

# Згенерувати configure
echo "🔧 Generating configure..."
./autogen.sh

# Налаштувати збірку без GUI
echo "⚙️ Configuring build (CLI only)..."
CONFIG_SITE=$PWD/depends/x86_64-w64-mingw32/share/config.site ./configure \
    --prefix=/ \
    --disable-tests \
    --disable-bench \
    --disable-fuzz-binary \
    --disable-gui \
    --without-natpmp \
    --without-miniupnpc \
    --disable-zmq \
    --disable-debug

# Збудувати всі CLI інструменти
echo "🔨 Building CLI tools with make -j8..."
make -j8

# Перевірити результат
if [ -f "src/bitcoind.exe" ] && [ -f "src/bitcoin-cli.exe" ]; then
    echo "✅ Build successful!"
    
    # Створити директорію для результату
    mkdir -p Krepto-Windows-Final
    
    # Копіювати всі виконувані файли
    echo "📦 Copying executables..."
    cp src/bitcoind.exe Krepto-Windows-Final/kryptod.exe
    cp src/bitcoin-cli.exe Krepto-Windows-Final/krypto-cli.exe
    cp src/bitcoin-tx.exe Krepto-Windows-Final/krypto-tx.exe
    cp src/bitcoin-util.exe Krepto-Windows-Final/krypto-util.exe
    
    # Копіювати необхідні DLL файли
    echo "📦 Copying DLL dependencies..."
    
    # Знайти та копіювати mingw DLL
    MINGW_PATH="/opt/homebrew/Cellar/mingw-w64"
    if [ -d "$MINGW_PATH" ]; then
        find "$MINGW_PATH" -name "libgcc_s_seh-1.dll" -exec cp {} Krepto-Windows-Final/ \; 2>/dev/null || true
        find "$MINGW_PATH" -name "libstdc++-6.dll" -exec cp {} Krepto-Windows-Final/ \; 2>/dev/null || true
        find "$MINGW_PATH" -name "libwinpthread-1.dll" -exec cp {} Krepto-Windows-Final/ \; 2>/dev/null || true
    fi
    
    # Додати конфігурацію
    cat > Krepto-Windows-Final/bitcoin.conf << 'EOF'
# Krepto Configuration
rpcuser=kreptouser
rpcpassword=kreptopass123
rpcport=12347
port=12345
server=1
daemon=1
addnode=164.68.117.90:12345

# Performance settings
dbcache=512
maxconnections=50
maxmempool=300

# Logging
debug=0
printtoconsole=0
EOF

    # Створити batch файли для зручності
    cat > Krepto-Windows-Final/start-daemon.bat << 'EOF'
@echo off
echo Starting Krepto daemon...
kryptod.exe -daemon
echo Daemon started successfully!
echo Use krypto-cli.exe for commands
pause
EOF

    cat > Krepto-Windows-Final/stop-daemon.bat << 'EOF'
@echo off
echo Stopping Krepto daemon...
krypto-cli.exe stop
echo Daemon stopped.
pause
EOF

    cat > Krepto-Windows-Final/get-info.bat << 'EOF'
@echo off
echo Getting Krepto blockchain info...
krypto-cli.exe getblockchaininfo
echo.
echo Getting wallet info...
krypto-cli.exe getwalletinfo
pause
EOF

    cat > Krepto-Windows-Final/start-mining.bat << 'EOF'
@echo off
echo Starting Krepto mining...
echo First, let's get a mining address...
for /f "tokens=*" %%a in ('krypto-cli.exe getnewaddress') do set MINING_ADDRESS=%%a
echo Mining address: %MINING_ADDRESS%
echo.
echo Starting mining to address %MINING_ADDRESS%...
krypto-cli.exe generatetoaddress 1 %MINING_ADDRESS% 10000000
echo Mining completed! Check your balance with get-info.bat
pause
EOF

    cat > Krepto-Windows-Final/create-wallet.bat << 'EOF'
@echo off
echo Creating new Krepto wallet...
krypto-cli.exe createwallet "default"
echo Wallet created successfully!
echo Getting new address...
krypto-cli.exe getnewaddress
pause
EOF

    # Створити детальний README
    cat > Krepto-Windows-Final/README.txt << 'EOF'
🚀 Krepto - Bitcoin Fork for Windows (Final Version)

QUICK START:
1. Run start-daemon.bat to start the Krepto daemon
2. Run create-wallet.bat to create a new wallet
3. Run start-mining.bat to mine some Krepto coins
4. Run get-info.bat to check your balance

EXECUTABLES:
- kryptod.exe - Main daemon (runs in background)
- krypto-cli.exe - Command line interface
- krypto-tx.exe - Transaction tools
- krypto-util.exe - Utility tools

BATCH FILES (Double-click to run):
- start-daemon.bat - Start Krepto daemon
- stop-daemon.bat - Stop Krepto daemon
- create-wallet.bat - Create new wallet
- start-mining.bat - Mine Krepto coins
- get-info.bat - Check blockchain and wallet info

NETWORK INFORMATION:
- Network: Krepto mainnet
- Port: 12345
- RPC Port: 12347
- Data Directory: %APPDATA%\Krepto\
- Seed Node: 164.68.117.90:12345

ADDRESSES:
- Legacy addresses start with 'K'
- SegWit addresses start with 'kr1q'
- Both types are fully supported

MINING:
- Fast mining (5,400+ blocks/hour)
- SegWit support from genesis block
- Use start-mining.bat for easy mining

CONFIGURATION:
- Config file: bitcoin.conf (in this folder)
- Copy to %APPDATA%\Krepto\ if needed
- Logs: %APPDATA%\Krepto\debug.log

TROUBLESHOOTING:
- Ensure port 12345 is not blocked by firewall
- Check debug.log for detailed information
- Make sure daemon is running before using CLI commands

SUPPORT:
- Built with Bitcoin Core technology
- Compatible with Bitcoin RPC commands
- Professional grade cryptocurrency

Enjoy mining Krepto! ⛏️💎

Built with ❤️ for Windows users
EOF

    # Створити ZIP архів
    echo "📦 Creating ZIP archive..."
    zip -r Krepto-Windows-Final.zip Krepto-Windows-Final/
    
    # Показати результат
    echo ""
    echo "🎊 SUCCESS! Krepto Windows Final build completed!"
    echo ""
    echo "📊 Build Results:"
    ls -lh Krepto-Windows-Final.zip
    echo ""
    echo "📁 Package Contents:"
    du -sh Krepto-Windows-Final/
    ls -la Krepto-Windows-Final/
    
    echo ""
    echo "🎯 Package Features:"
    echo "✅ All CLI tools included"
    echo "✅ Easy-to-use batch files"
    echo "✅ Complete configuration"
    echo "✅ Detailed documentation"
    echo "✅ Mining ready"
    echo "✅ Professional quality"
    
    echo ""
    echo "🚀 Ready for Windows distribution!"
    
else
    echo "❌ Build failed!"
    exit 1
fi 