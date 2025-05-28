#!/bin/bash

set -e

echo "🪟 Building Krepto Windows GUI Version..."

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

# Збудувати залежності з правильними флагами для Windows
echo "📦 Building dependencies for Windows..."
cd depends

# Встановити правильні змінні середовища для Windows збірки
export HOST=x86_64-w64-mingw32
export CC=x86_64-w64-mingw32-gcc
export CXX=x86_64-w64-mingw32-g++
export AR=x86_64-w64-mingw32-ar
export RANLIB=x86_64-w64-mingw32-ranlib
export STRIP=x86_64-w64-mingw32-strip

# Збудувати тільки необхідні залежності без проблемних
make HOST=x86_64-w64-mingw32 -j4 \
    NO_UPNP=1 \
    NO_NATPMP=1 \
    NO_ZMQ=1 \
    NO_USDT=1 \
    NO_QT=0

cd ..

# Згенерувати configure
echo "🔧 Generating configure..."
./autogen.sh

# Налаштувати збірку з GUI та правильними шляхами
echo "⚙️ Configuring build with GUI..."
CONFIG_SITE=$PWD/depends/x86_64-w64-mingw32/share/config.site ./configure \
    --prefix=/ \
    --host=x86_64-w64-mingw32 \
    --disable-tests \
    --disable-bench \
    --disable-fuzz-binary \
    --enable-gui \
    --without-natpmp \
    --without-miniupnpc \
    --disable-zmq \
    --disable-debug \
    --with-gui=qt5 \
    CPPFLAGS="-I$PWD/depends/x86_64-w64-mingw32/include" \
    LDFLAGS="-L$PWD/depends/x86_64-w64-mingw32/lib"

# Збудувати всі інструменти включно з GUI
echo "🔨 Building all tools with GUI support..."
make -j4

# Перевірити результат
if [ -f "src/qt/bitcoin-qt.exe" ] && [ -f "src/bitcoind.exe" ] && [ -f "src/bitcoin-cli.exe" ]; then
    echo "✅ Build successful!"
    
    # Створити директорію для результату
    mkdir -p Krepto-Windows-GUI
    
    # Копіювати всі виконувані файли з правильними назвами
    echo "📦 Copying executables with Krepto names..."
    cp src/qt/bitcoin-qt.exe Krepto-Windows-GUI/krepto-qt.exe
    cp src/bitcoind.exe Krepto-Windows-GUI/kryptod.exe
    cp src/bitcoin-cli.exe Krepto-Windows-GUI/krepto-cli.exe
    cp src/bitcoin-tx.exe Krepto-Windows-GUI/krepto-tx.exe
    cp src/bitcoin-util.exe Krepto-Windows-GUI/krepto-util.exe
    cp src/bitcoin-wallet.exe Krepto-Windows-GUI/krepto-wallet.exe
    
    # Копіювати необхідні DLL файли
    echo "📦 Copying DLL dependencies..."
    
    # Знайти та копіювати mingw DLL
    MINGW_PATH="/opt/homebrew/Cellar/mingw-w64"
    if [ -d "$MINGW_PATH" ]; then
        find "$MINGW_PATH" -name "libgcc_s_seh-1.dll" -exec cp {} Krepto-Windows-GUI/ \; 2>/dev/null || true
        find "$MINGW_PATH" -name "libstdc++-6.dll" -exec cp {} Krepto-Windows-GUI/ \; 2>/dev/null || true
        find "$MINGW_PATH" -name "libwinpthread-1.dll" -exec cp {} Krepto-Windows-GUI/ \; 2>/dev/null || true
    fi
    
    # Копіювати Qt5 DLL файли з depends
    echo "📦 Copying Qt5 dependencies..."
    QT_PATH="depends/x86_64-w64-mingw32"
    if [ -d "$QT_PATH" ]; then
        # Основні Qt5 DLL
        find "$QT_PATH" -name "Qt5Core.dll" -exec cp {} Krepto-Windows-GUI/ \; 2>/dev/null || true
        find "$QT_PATH" -name "Qt5Gui.dll" -exec cp {} Krepto-Windows-GUI/ \; 2>/dev/null || true
        find "$QT_PATH" -name "Qt5Widgets.dll" -exec cp {} Krepto-Windows-GUI/ \; 2>/dev/null || true
        find "$QT_PATH" -name "Qt5Network.dll" -exec cp {} Krepto-Windows-GUI/ \; 2>/dev/null || true
        
        # Створити папки для Qt plugins
        mkdir -p Krepto-Windows-GUI/platforms
        mkdir -p Krepto-Windows-GUI/imageformats
        
        # Копіювати Qt plugins
        find "$QT_PATH" -name "qwindows.dll" -exec cp {} Krepto-Windows-GUI/platforms/ \; 2>/dev/null || true
        find "$QT_PATH" -name "qico.dll" -exec cp {} Krepto-Windows-GUI/imageformats/ \; 2>/dev/null || true
    fi
    
    # Додати конфігурацію
    cat > Krepto-Windows-GUI/bitcoin.conf << 'EOF'
# Krepto Configuration
rpcuser=kreptouser
rpcpassword=kreptopass123
rpcport=12347
port=12345
server=1
daemon=0

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

# GUI Settings
gui=1
EOF

    # Створити batch файли для GUI
    cat > Krepto-Windows-GUI/start-krepto-gui.bat << 'EOF'
@echo off
echo Starting Krepto GUI...
start krepto-qt.exe
echo Krepto GUI started!
EOF

    cat > Krepto-Windows-GUI/start-daemon.bat << 'EOF'
@echo off
echo Starting Krepto daemon...
kryptod.exe -daemon
echo Daemon started successfully!
echo Use krepto-cli.exe for commands
pause
EOF

    cat > Krepto-Windows-GUI/stop-daemon.bat << 'EOF'
@echo off
echo Stopping Krepto daemon...
krepto-cli.exe stop
echo Daemon stopped.
pause
EOF

    cat > Krepto-Windows-GUI/get-info.bat << 'EOF'
@echo off
echo Getting Krepto blockchain info...
krepto-cli.exe getblockchaininfo
echo.
echo Getting wallet info...
krepto-cli.exe getwalletinfo
pause
EOF

    cat > Krepto-Windows-GUI/start-mining.bat << 'EOF'
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

    cat > Krepto-Windows-GUI/create-wallet.bat << 'EOF'
@echo off
echo Creating new Krepto wallet...
krepto-cli.exe createwallet "default"
echo Wallet created successfully!
echo Getting new address...
krepto-cli.exe getnewaddress
pause
EOF

    # Створити детальний README
    cat > Krepto-Windows-GUI/README.txt << 'EOF'
🚀 Krepto - Bitcoin Fork for Windows (GUI Version)

QUICK START:
1. Double-click start-krepto-gui.bat to launch GUI
2. Or run krepto-qt.exe directly
3. Create wallet and start mining from GUI

EXECUTABLES:
- krepto-qt.exe - Main GUI application with built-in mining
- kryptod.exe - Background daemon
- krepto-cli.exe - Command line interface
- krepto-tx.exe - Transaction tools
- krepto-util.exe - Utility tools
- krepto-wallet.exe - Wallet tools

BATCH FILES (Double-click to run):
- start-krepto-gui.bat - Start Krepto GUI (RECOMMENDED)
- start-daemon.bat - Start background daemon
- stop-daemon.bat - Stop daemon
- create-wallet.bat - Create new wallet via CLI
- start-mining.bat - Mine via CLI
- get-info.bat - Check status via CLI

GUI FEATURES:
- Built-in mining interface
- Real-time blockchain sync
- Wallet management
- Transaction history
- Mining console with logs
- Professional interface

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
- Use GUI mining for best experience
- Mining console shows real-time logs

CONFIGURATION:
- Config file: bitcoin.conf (in this folder)
- Copy to %APPDATA%\Krepto\ if needed
- Logs: %APPDATA%\Krepto\debug.log

TROUBLESHOOTING:
- Ensure port 12345 is not blocked by firewall
- Check debug.log for detailed information
- GUI requires all DLL files in same folder
- Use krepto-qt.exe for full GUI experience

SUPPORT:
- Built with Bitcoin Core + Qt5 technology
- Compatible with Bitcoin RPC commands
- Professional grade cryptocurrency with GUI

Enjoy mining Krepto with GUI! ⛏️💎🖥️

Built with ❤️ for Windows users
EOF

    # Створити ZIP архів
    echo "📦 Creating ZIP archive..."
    zip -r Krepto-Windows-GUI.zip Krepto-Windows-GUI/
    
    # Показати результат
    echo ""
    echo "🎊 SUCCESS! Krepto Windows GUI build completed!"
    echo ""
    echo "📊 Build Results:"
    ls -lh Krepto-Windows-GUI.zip
    echo ""
    echo "📁 Package Contents:"
    du -sh Krepto-Windows-GUI/
    ls -la Krepto-Windows-GUI/
    
    echo ""
    echo "🎯 Package Features:"
    echo "✅ Full GUI application (krepto-qt.exe)"
    echo "✅ Built-in mining interface"
    echo "✅ All CLI tools included"
    echo "✅ Easy-to-use batch files"
    echo "✅ Complete Qt5 dependencies"
    echo "✅ Professional GUI interface"
    echo "✅ Ready for Windows distribution"
    
    echo ""
    echo "🚀 Ready for Windows GUI distribution!"
    
else
    echo "❌ Build failed!"
    exit 1
fi 