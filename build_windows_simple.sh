#!/bin/bash

set -e

echo "🪟 Building Krepto Windows (CLI only)..."

# Перевірити чи встановлений mingw-w64
if ! command -v x86_64-w64-mingw32-gcc &> /dev/null; then
    echo "❌ mingw-w64 not found. Installing..."
    brew install mingw-w64
fi

echo "✅ mingw-w64 found: $(x86_64-w64-mingw32-gcc --version | head -1)"

# Очистити попередні збірки
echo "🧹 Cleaning previous builds..."
rm -rf depends/x86_64-w64-mingw32
rm -rf Krepto-Windows-CLI
rm -f Krepto-Windows-CLI.zip

# Збудувати залежності для Windows (без Qt5)
echo "📦 Building dependencies for Windows (no GUI)..."
cd depends
make HOST=x86_64-w64-mingw32 NO_QT=1 -j8
cd ..

# Згенерувати configure скрипт
echo "🔧 Generating configure script..."
./autogen.sh

# Налаштувати збірку для Windows (без GUI)
echo "⚙️ Configuring for Windows build (CLI only)..."
CONFIG_SITE=$PWD/depends/x86_64-w64-mingw32/share/config.site ./configure \
    --prefix=/ \
    --disable-tests \
    --disable-bench \
    --disable-gui \
    --without-gui

# Збудувати Krepto для Windows
echo "🔨 Building Krepto for Windows..."
make -j8

# Створити структуру для інсталятора
echo "📁 Creating installer structure..."
mkdir -p Krepto-Windows-CLI

# Копіювати виконувані файли
echo "📋 Copying executables..."
cp src/bitcoind.exe Krepto-Windows-CLI/kryptod.exe
cp src/bitcoin-cli.exe Krepto-Windows-CLI/krypto-cli.exe
cp src/bitcoin-tx.exe Krepto-Windows-CLI/krypto-tx.exe
cp src/bitcoin-util.exe Krepto-Windows-CLI/krypto-util.exe

# Копіювати необхідні DLL
echo "📚 Copying required libraries..."
# Знайти та скопіювати mingw DLL
MINGW_PATH="/opt/homebrew/Cellar/mingw-w64"
if [ -d "$MINGW_PATH" ]; then
    find $MINGW_PATH -name "*.dll" -exec cp {} Krepto-Windows-CLI/ \; 2>/dev/null || true
fi

# Створити конфігурацію
echo "⚙️ Creating Krepto configuration..."
cat > Krepto-Windows-CLI/bitcoin.conf << 'EOF'
# Krepto Client Configuration

# Network Settings
port=12345
rpcport=12347

# Connection to Seed Node
addnode=164.68.117.90:12345
connect=164.68.117.90:12345

# Node Settings
daemon=1
server=1
listen=1

# RPC Settings
rpcuser=localuser
rpcpassword=localpass123
rpcbind=127.0.0.1
rpcallowip=127.0.0.1

# Logging
debug=net
logips=1

# Performance
dbcache=512
maxmempool=300

# Force Krepto network (prevent Bitcoin connection)
onlynet=ipv4
discover=0
dnsseed=0
EOF

# Створити batch файли для запуску
echo "📝 Creating batch files..."
cat > Krepto-Windows-CLI/start-daemon.bat << 'EOF'
@echo off
echo Starting Krepto Daemon...
kryptod.exe -datadir=%APPDATA%\Krepto
pause
EOF

cat > Krepto-Windows-CLI/stop-daemon.bat << 'EOF'
@echo off
echo Stopping Krepto Daemon...
krypto-cli.exe -datadir=%APPDATA%\Krepto stop
pause
EOF

cat > Krepto-Windows-CLI/get-info.bat << 'EOF'
@echo off
echo Krepto Network Info:
krypto-cli.exe -datadir=%APPDATA%\Krepto getblockchaininfo
echo.
echo Wallet Info:
krypto-cli.exe -datadir=%APPDATA%\Krepto getwalletinfo
pause
EOF

cat > Krepto-Windows-CLI/start-mining.bat << 'EOF'
@echo off
echo Getting mining address...
for /f %%i in ('krypto-cli.exe -datadir=%APPDATA%\Krepto getnewaddress') do set ADDR=%%i
echo Mining to address: %ADDR%
echo Starting mining (press Ctrl+C to stop)...
krypto-cli.exe -datadir=%APPDATA%\Krepto generatetoaddress 1000000 %ADDR% 10000000
pause
EOF

# Створити README для Windows
echo "📝 Creating README for Windows..."
cat > Krepto-Windows-CLI/README.txt << 'EOF'
🚀 Krepto - Bitcoin Fork for Windows (CLI Version)

INSTALLATION:
1. Extract all files to a folder (e.g., C:\Krepto)
2. Copy bitcoin.conf to %APPDATA%\Krepto\
3. Run start-daemon.bat to start the daemon

EXECUTABLES:
- kryptod.exe - Main daemon
- krypto-cli.exe - Command line interface
- krypto-tx.exe - Transaction tools
- krypto-util.exe - Utility tools

BATCH FILES:
- start-daemon.bat - Start Krepto daemon
- stop-daemon.bat - Stop Krepto daemon
- get-info.bat - Show network and wallet info
- start-mining.bat - Start mining Krepto

NETWORK INFO:
- Krepto uses its own blockchain (not Bitcoin)
- Connects to seed node: 164.68.117.90:12345
- Data stored in: %APPDATA%\Krepto\
- Addresses start with 'K' (legacy) or 'kr1q' (SegWit)

FEATURES:
- Command line mining
- SegWit support from genesis
- Fast block generation
- Compatible with Bitcoin Core RPC

CONFIGURATION:
- Config file: %APPDATA%\Krepto\bitcoin.conf
- Logs: %APPDATA%\Krepto\debug.log
- Network: Krepto mainnet (port 12345)

MINING:
1. Run start-daemon.bat
2. Wait for synchronization
3. Run start-mining.bat
4. Enjoy mining Krepto! ⛏️

COMMANDS:
- krypto-cli.exe getblockchaininfo
- krypto-cli.exe getwalletinfo
- krypto-cli.exe getnewaddress
- krypto-cli.exe generatetoaddress 1 <address> 10000000

SUPPORT:
- Check %APPDATA%\Krepto\debug.log for troubleshooting
- Ensure port 12345 is not blocked by firewall
- For help, check the configuration file

Enjoy mining Krepto! 🎉
EOF

# Перевірити розміри файлів
echo "📊 File sizes:"
ls -lh Krepto-Windows-CLI/

# Створити ZIP архів
echo "📦 Creating ZIP archive..."
zip -r Krepto-Windows-CLI.zip Krepto-Windows-CLI/

# Показати результат
echo "✅ Windows CLI build completed successfully!"
echo "📋 Build info:"
echo "- Executables: kryptod.exe, krypto-cli.exe, krypto-tx.exe, krypto-util.exe"
echo "- Batch files: start-daemon.bat, stop-daemon.bat, get-info.bat, start-mining.bat"
echo "- Configuration: bitcoin.conf included"
echo "- Documentation: README.txt included"
echo "- Archive: Krepto-Windows-CLI.zip"

echo ""
echo "📦 Archive contents:"
unzip -l Krepto-Windows-CLI.zip

echo ""
echo "🎯 Next steps:"
echo "1. Test on Windows VM"
echo "2. Create GUI version with Docker"
echo "3. Upload for distribution"

echo ""
echo "🎊 Krepto Windows CLI build ready for testing!" 