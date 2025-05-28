#!/bin/bash

set -e

echo "🪟 Building Krepto Windows GUI (Simple approach)..."

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

# Виправити проблеми з іконками
echo "🔧 Fixing icon issues..."
mkdir -p src/qt/res/icons

# Створити всі необхідні іконки як placeholder
for icon in bitcoin bitcoin_testnet bitcoin_regtest bitcoin_signet; do
    if [ ! -f "src/qt/res/icons/${icon}.ico" ]; then
        echo "Creating placeholder for ${icon}.ico"
        echo "# Placeholder ${icon}.ico" > "src/qt/res/icons/${icon}.ico"
    fi
done

# Перевірити чи збудовані залежності
if [ ! -d "depends/x86_64-w64-mingw32" ]; then
    echo "📦 Building dependencies..."
    cd depends
    make HOST=x86_64-w64-mingw32 -j8 \
        NO_UPNP=1 \
        NO_NATPMP=1 \
        NO_ZMQ=1 \
        NO_USDT=1
    cd ..
else
    echo "✅ Dependencies already built"
fi

# Згенерувати configure якщо потрібно
if [ ! -f "configure" ]; then
    echo "🔧 Generating configure..."
    ./autogen.sh
fi

# Налаштувати збірку
echo "⚙️ Configuring build..."
CONFIG_SITE=$PWD/depends/x86_64-w64-mingw32/share/config.site ./configure \
    --prefix=/ \
    --disable-tests \
    --disable-bench \
    --disable-fuzz-binary \
    --enable-gui \
    --without-natpmp \
    --without-miniupnpc \
    --disable-zmq \
    --disable-debug

# Збудувати тільки GUI
echo "🔨 Building GUI (this may take 15-20 minutes)..."
make -j8 src/qt/bitcoin-qt.exe

# Перевірити чи збудувалося
if [ -f "src/qt/bitcoin-qt.exe" ]; then
    echo "✅ GUI build successful!"
    
    # Створити директорію для результату
    mkdir -p Krepto-Windows-GUI-Simple
    
    # Копіювати файли
    echo "📦 Copying files..."
    cp src/qt/bitcoin-qt.exe Krepto-Windows-GUI-Simple/Krepto.exe
    
    # Збудувати CLI інструменти якщо потрібно
    if [ ! -f "src/bitcoind.exe" ]; then
        echo "🔨 Building CLI tools..."
        make -j8 src/bitcoind.exe src/bitcoin-cli.exe
    fi
    
    cp src/bitcoind.exe Krepto-Windows-GUI-Simple/kryptod.exe
    cp src/bitcoin-cli.exe Krepto-Windows-GUI-Simple/krypto-cli.exe
    
    # Додати конфігурацію
    cat > Krepto-Windows-GUI-Simple/bitcoin.conf << 'EOF'
# Krepto Configuration
rpcuser=kreptouser
rpcpassword=kreptopass123
rpcport=12347
port=12345
server=1
daemon=1
addnode=164.68.117.90:12345
EOF

    # Додати README
    cat > Krepto-Windows-GUI-Simple/README.txt << 'EOF'
🚀 Krepto - Bitcoin Fork for Windows (GUI Version)

QUICK START:
1. Run Krepto.exe to start the GUI
2. Go to Mining menu -> Start Mining
3. Enjoy mining Krepto! ⛏️

FILES:
- Krepto.exe - Main GUI application
- kryptod.exe - Daemon
- krypto-cli.exe - CLI tools
- bitcoin.conf - Configuration file

NETWORK:
- Port: 12345
- RPC Port: 12347
- Data: %APPDATA%\Krepto\

Built with ❤️ for Windows
EOF

    # Створити ZIP
    echo "📦 Creating ZIP archive..."
    zip -r Krepto-Windows-GUI-Simple.zip Krepto-Windows-GUI-Simple/
    
    # Показати результат
    echo ""
    echo "🎊 SUCCESS! Krepto Windows GUI built successfully!"
    echo "📊 Results:"
    ls -lh Krepto-Windows-GUI-Simple.zip
    du -sh Krepto-Windows-GUI-Simple/
    
    echo ""
    echo "🎯 Ready for testing on Windows!"
    
else
    echo "❌ GUI build failed!"
    exit 1
fi 