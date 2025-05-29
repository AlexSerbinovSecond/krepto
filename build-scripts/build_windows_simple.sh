#!/bin/bash

set -e

echo "🪟 Building Krepto Windows CLI Version (Simple)..."

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

# Очистити depends
echo "🧹 Cleaning depends..."
cd depends
make clean HOST=x86_64-w64-mingw32 2>/dev/null || true
cd ..

# Збудувати мінімальні залежності для Windows CLI
echo "📦 Building minimal dependencies for Windows CLI..."
cd depends

# Збудувати тільки базові залежності без Qt
make HOST=x86_64-w64-mingw32 -j4 \
    NO_UPNP=1 \
    NO_NATPMP=1 \
    NO_ZMQ=1 \
    NO_USDT=1 \
    NO_QT=1

cd ..

# Згенерувати configure
echo "🔧 Generating configure..."
./autogen.sh

# Налаштувати збірку без GUI
echo "⚙️ Configuring build without GUI..."
CONFIG_SITE=$PWD/depends/x86_64-w64-mingw32/share/config.site ./configure \
    --prefix=/ \
    --host=x86_64-w64-mingw32 \
    --disable-tests \
    --disable-bench \
    --disable-fuzz-binary \
    --disable-gui \
    --without-natpmp \
    --without-miniupnpc \
    --disable-zmq \
    --disable-debug

# Збудувати CLI інструменти
echo "🔨 Building CLI tools..."
make -j4

# Перевірити результат
if [ -f "src/bitcoind.exe" ] && [ -f "src/bitcoin-cli.exe" ]; then
    echo "✅ Build successful!"
    
    # Створити директорію для результату
    mkdir -p Krepto-Windows-CLI-Simple
    
    # Копіювати всі виконувані файли з правильними назвами
    echo "📦 Copying executables with Krepto names..."
    cp src/bitcoind.exe Krepto-Windows-CLI-Simple/kryptod.exe
    cp src/bitcoin-cli.exe Krepto-Windows-CLI-Simple/krepto-cli.exe
    cp src/bitcoin-tx.exe Krepto-Windows-CLI-Simple/krepto-tx.exe
    cp src/bitcoin-util.exe Krepto-Windows-CLI-Simple/krepto-util.exe
    cp src/bitcoin-wallet.exe Krepto-Windows-CLI-Simple/krepto-wallet.exe
    
    # Копіювати необхідні DLL файли
    echo "📦 Copying DLL dependencies..."
    
    # Знайти та копіювати mingw DLL
    MINGW_PATH="/opt/homebrew/Cellar/mingw-w64"
    if [ -d "$MINGW_PATH" ]; then
        find "$MINGW_PATH" -name "libgcc_s_seh-1.dll" -exec cp {} Krepto-Windows-CLI-Simple/ \; 2>/dev/null || true
        find "$MINGW_PATH" -name "libstdc++-6.dll" -exec cp {} Krepto-Windows-CLI-Simple/ \; 2>/dev/null || true
        find "$MINGW_PATH" -name "libwinpthread-1.dll" -exec cp {} Krepto-Windows-CLI-Simple/ \; 2>/dev/null || true
    fi
    
    # Додати конфігурацію
    cat > Krepto-Windows-CLI-Simple/bitcoin.conf << 'EOF'
# Krepto Configuration
rpcuser=kreptouser
rpcpassword=kreptopass123
rpcport=12347
port=12345
server=1
daemon=1

# Working seed nodes
addnode=164.68.117.90:12345
addnode=5.189.133.204:12345

# Performance settings
dbcache=512
maxconnections=50
maxmempool=300

# Logging
debug=0
printtoconsole=0

# Network reliability
timeout=30000
connect=164.68.117.90:12345
connect=5.189.133.204:12345
EOF

    # Створити batch файли
    cat > Krepto-Windows-CLI-Simple/start-daemon.bat << 'EOF'
@echo off
echo Starting Krepto daemon...
kryptod.exe -daemon
echo Daemon started successfully!
echo Use krepto-cli.exe for commands
pause
EOF

    cat > Krepto-Windows-CLI-Simple/stop-daemon.bat << 'EOF'
@echo off
echo Stopping Krepto daemon...
krepto-cli.exe stop
echo Daemon stopped.
pause
EOF

    cat > Krepto-Windows-CLI-Simple/get-info.bat << 'EOF'
@echo off
echo Getting Krepto blockchain info...
krepto-cli.exe getblockchaininfo
echo.
echo Getting wallet info...
krepto-cli.exe getwalletinfo
pause
EOF

    cat > Krepto-Windows-CLI-Simple/start-mining.bat << 'EOF'
@echo off
echo Starting Krepto mining...
echo First, let's get a mining address...
for /f "tokens=*" %%a in ('krepto-cli.exe getnewaddress') do set MINING_ADDRESS=%%a
echo Mining address: %MINING_ADDRESS%
echo.
echo Starting mining to address %MINING_ADDRESS%...
krepto-cli.exe generatetoaddress 1 %MINING_ADDRESS% 10000000
echo Mining completed! Check your balance with get-info.bat
pause
EOF

    cat > Krepto-Windows-CLI-Simple/create-wallet.bat << 'EOF'
@echo off
echo Creating new Krepto wallet...
krepto-cli.exe createwallet "default"
echo Wallet created successfully!
echo Getting new address...
krepto-cli.exe getnewaddress
pause
EOF

    # Створити README
    cat > Krepto-Windows-CLI-Simple/README.txt << 'EOF'
🚀 Krepto - Bitcoin Fork for Windows (CLI Version)

QUICK START:
1. Double-click start-daemon.bat to start daemon
2. Double-click create-wallet.bat to create wallet
3. Double-click start-mining.bat to mine

EXECUTABLES:
- kryptod.exe - Background daemon
- krepto-cli.exe - Command line interface
- krepto-tx.exe - Transaction tools
- krepto-util.exe - Utility tools
- krepto-wallet.exe - Wallet tools

BATCH FILES (Double-click to run):
- start-daemon.bat - Start background daemon
- stop-daemon.bat - Stop daemon
- create-wallet.bat - Create new wallet
- start-mining.bat - Mine blocks
- get-info.bat - Check status

NETWORK INFORMATION:
- Network: Krepto mainnet
- Port: 12345
- RPC Port: 12347
- Data Directory: %APPDATA%\Krepto\
- Seed Nodes: 
  * 164.68.117.90:12345
  * 5.189.133.204:12345

ADDRESSES:
- Legacy addresses start with 'K'
- SegWit addresses start with 'kr1q'
- Both types fully supported

MINING:
- Fast mining (5,400+ blocks/hour)
- SegWit support from genesis block
- Use start-mining.bat for easy mining

CONFIGURATION:
- Config file: bitcoin.conf (in this folder)
- Copy to %APPDATA%\Krepto\ if needed
- Logs: %APPDATA%\Krepto\debug.log

Built with ❤️ for Windows users
EOF

    # Створити ZIP архів
    echo "📦 Creating ZIP archive..."
    zip -r Krepto-Windows-CLI-Simple.zip Krepto-Windows-CLI-Simple/
    
    # Показати результат
    echo ""
    echo "🎊 SUCCESS! Krepto Windows CLI build completed!"
    echo ""
    echo "📊 Build Results:"
    ls -lh Krepto-Windows-CLI-Simple.zip
    echo ""
    echo "📁 Package Contents:"
    du -sh Krepto-Windows-CLI-Simple/
    ls -la Krepto-Windows-CLI-Simple/
    
    echo ""
    echo "🎯 Package Features:"
    echo "✅ All CLI tools with Krepto names"
    echo "✅ Easy-to-use batch files"
    echo "✅ Complete mining functionality"
    echo "✅ Minimal dependencies"
    echo "✅ Ready for Windows distribution"
    
    echo ""
    echo "🚀 Ready for Windows CLI distribution!"
    
else
    echo "❌ Build failed!"
    exit 1
fi 