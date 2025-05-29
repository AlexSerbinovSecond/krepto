#!/bin/bash

set -e

echo "🪟 Building Krepto Windows Installer..."

# Перевірити чи встановлений mingw-w64
if ! command -v x86_64-w64-mingw32-gcc &> /dev/null; then
    echo "❌ mingw-w64 not found. Installing..."
    brew install mingw-w64
fi

echo "✅ mingw-w64 found: $(x86_64-w64-mingw32-gcc --version | head -1)"

# Очистити попередні збірки
echo "🧹 Cleaning previous builds..."
rm -rf depends/x86_64-w64-mingw32
rm -rf Krepto-Windows
rm -f Krepto-Setup.exe

# Збудувати залежності для Windows
echo "📦 Building dependencies for Windows..."
cd depends
make HOST=x86_64-w64-mingw32 -j8
cd ..

# Згенерувати configure скрипт
echo "🔧 Generating configure script..."
./autogen.sh

# Налаштувати збірку для Windows
echo "⚙️ Configuring for Windows build..."
CONFIG_SITE=$PWD/depends/x86_64-w64-mingw32/share/config.site ./configure \
    --prefix=/ \
    --disable-tests \
    --disable-bench \
    --enable-gui

# Збудувати Krepto для Windows
echo "🔨 Building Krepto for Windows..."
make -j8

# Створити структуру для інсталятора
echo "📁 Creating installer structure..."
mkdir -p Krepto-Windows

# Копіювати виконувані файли
echo "📋 Copying executables..."
cp src/qt/bitcoin-qt.exe Krepto-Windows/Krepto.exe
cp src/bitcoind.exe Krepto-Windows/kryptod.exe
cp src/bitcoin-cli.exe Krepto-Windows/krypto-cli.exe

# Копіювати Qt5 DLL файли
echo "📚 Copying Qt5 libraries..."
QT_PATH="depends/x86_64-w64-mingw32"

# Створити папку для DLL
mkdir -p Krepto-Windows/platforms

# Копіювати основні Qt5 DLL
if [ -d "$QT_PATH/lib" ]; then
    find $QT_PATH/lib -name "*.dll" -exec cp {} Krepto-Windows/ \;
fi

if [ -d "$QT_PATH/bin" ]; then
    find $QT_PATH/bin -name "*.dll" -exec cp {} Krepto-Windows/ \;
fi

# Копіювати Qt5 plugins
if [ -d "$QT_PATH/plugins/platforms" ]; then
    cp $QT_PATH/plugins/platforms/*.dll Krepto-Windows/platforms/ 2>/dev/null || true
fi

# Створити конфігурацію
echo "⚙️ Creating Krepto configuration..."
cat > Krepto-Windows/bitcoin.conf << 'EOF'
# Krepto Client Configuration

# Network Settings
port=12345
rpcport=12347

# Connection to Seed Node
addnode=164.68.117.90:12345
connect=164.68.117.90:12345

# Node Settings
daemon=0
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

# Disable mining on client
gen=0

# GUI Settings
gui=1

# Performance
dbcache=512
maxmempool=300

# Force Krepto network (prevent Bitcoin connection)
onlynet=ipv4
discover=0
dnsseed=0
EOF

# Створити README для Windows
echo "📝 Creating README for Windows..."
cat > Krepto-Windows/README.txt << 'EOF'
🚀 Krepto - Bitcoin Fork for Windows

INSTALLATION:
1. Extract all files to a folder (e.g., C:\Krepto)
2. Run Krepto.exe to start the GUI
3. Wait for synchronization with Krepto network

EXECUTABLES:
- Krepto.exe - Main GUI application
- kryptod.exe - Daemon (command line)
- krypto-cli.exe - CLI tools

NETWORK INFO:
- Krepto uses its own blockchain (not Bitcoin)
- Connects to seed node: 164.68.117.90:12345
- Data stored in: %APPDATA%\Krepto\
- Addresses start with 'K' (legacy) or 'kr1q' (SegWit)

FEATURES:
- GUI Mining built-in
- SegWit support from genesis
- Fast block generation
- Compatible with Bitcoin Core RPC

CONFIGURATION:
- Config file: %APPDATA%\Krepto\bitcoin.conf
- Logs: %APPDATA%\Krepto\debug.log
- Network: Krepto mainnet (port 12345)

MINING:
1. Open Krepto.exe
2. Go to Mining menu
3. Click "Start Mining"
4. Enjoy mining Krepto! ⛏️

SUPPORT:
- Check debug.log for troubleshooting
- Ensure port 12345 is not blocked by firewall
- For help, check the configuration file

Enjoy mining Krepto! 🎉
EOF

# Перевірити розміри файлів
echo "📊 File sizes:"
ls -lh Krepto-Windows/

# Створити ZIP архів
echo "📦 Creating ZIP archive..."
zip -r Krepto-Windows.zip Krepto-Windows/

# Показати результат
echo "✅ Windows build completed successfully!"
echo "📋 Build info:"
echo "- Executables: Krepto.exe, kryptod.exe, krypto-cli.exe"
echo "- Configuration: bitcoin.conf included"
echo "- Documentation: README.txt included"
echo "- Archive: Krepto-Windows.zip"

echo ""
echo "📦 Archive contents:"
unzip -l Krepto-Windows.zip

echo ""
echo "🎯 Next steps:"
echo "1. Test on Windows VM"
echo "2. Create NSIS installer (optional)"
echo "3. Upload for distribution"

echo ""
echo "🎊 Krepto Windows build ready for testing!" 