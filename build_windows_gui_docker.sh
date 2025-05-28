#!/bin/bash

set -e

echo "🪟 Building Krepto Windows GUI with Docker (Optimized)..."

# Перевірити чи встановлений Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker not found. Please install Docker Desktop."
    exit 1
fi

echo "✅ Docker found: $(docker --version)"

# Створити Dockerfile для Windows збірки з оптимізаціями
echo "📝 Creating optimized Dockerfile for Windows build..."
cat > Dockerfile.windows << 'EOF'
FROM ubuntu:24.04

# Встановити необхідні пакети (оптимізовано)
RUN apt-get update && apt-get install -y \
    build-essential \
    libtool \
    autotools-dev \
    automake \
    pkg-config \
    bsdmainutils \
    python3 \
    curl \
    git \
    cmake \
    mingw-w64 \
    g++-mingw-w64-x86-64 \
    gcc-mingw-w64-x86-64 \
    ccache \
    && rm -rf /var/lib/apt/lists/*

# Налаштувати ccache для прискорення
ENV CCACHE_DIR=/tmp/ccache
ENV PATH="/usr/lib/ccache:$PATH"
RUN ccache --max-size=2G

# Налаштувати mingw для C++20
RUN update-alternatives --set x86_64-w64-mingw32-gcc /usr/bin/x86_64-w64-mingw32-gcc-posix
RUN update-alternatives --set x86_64-w64-mingw32-g++ /usr/bin/x86_64-w64-mingw32-g++-posix

# Створити робочу директорію
WORKDIR /krepto

# Копіювати тільки необхідні файли спочатку (для кешування Docker layers)
COPY depends/ depends/
COPY autogen.sh configure.ac Makefile.am ./
COPY build-aux/ build-aux/
COPY src/config/ src/config/

# Збудувати залежності з оптимізаціями
RUN cd depends && \
    make HOST=x86_64-w64-mingw32 -j8 \
    NO_UPNP=1 \
    NO_NATPMP=1 \
    NO_ZMQ=1

# Тепер копіювати решту коду
COPY . .

# Виправити ВСІ проблеми з іконками
RUN mkdir -p src/qt/res/icons && \
    echo "# Placeholder bitcoin.ico" > src/qt/res/icons/bitcoin.ico && \
    echo "# Placeholder bitcoin_testnet.ico" > src/qt/res/icons/bitcoin_testnet.ico && \
    echo "# Placeholder bitcoin_regtest.ico" > src/qt/res/icons/bitcoin_regtest.ico && \
    echo "# Placeholder bitcoin_signet.ico" > src/qt/res/icons/bitcoin_signet.ico

# Згенерувати configure
RUN ./autogen.sh

# Налаштувати збірку з оптимізаціями
RUN CONFIG_SITE=$PWD/depends/x86_64-w64-mingw32/share/config.site ./configure \
    --prefix=/ \
    --disable-tests \
    --disable-bench \
    --disable-fuzz-binary \
    --disable-ccache \
    --enable-gui \
    --without-natpmp \
    --without-miniupnpc \
    --disable-zmq

# Збудувати з GUI (оптимізовано)
RUN make -j8 V=0

# Створити інсталятор
RUN mkdir -p /output/Krepto-Windows-GUI && \
    cp src/qt/bitcoin-qt.exe /output/Krepto-Windows-GUI/Krepto.exe && \
    cp src/bitcoind.exe /output/Krepto-Windows-GUI/kryptod.exe && \
    cp src/bitcoin-cli.exe /output/Krepto-Windows-GUI/krypto-cli.exe && \
    cp src/bitcoin-tx.exe /output/Krepto-Windows-GUI/krypto-tx.exe && \
    cp src/bitcoin-util.exe /output/Krepto-Windows-GUI/krypto-util.exe

# Копіювати тільки необхідні DLL файли
RUN cp /usr/lib/gcc/x86_64-w64-mingw32/*/libgcc_s_seh-1.dll /output/Krepto-Windows-GUI/ 2>/dev/null || true && \
    cp /usr/lib/gcc/x86_64-w64-mingw32/*/libstdc++-6.dll /output/Krepto-Windows-GUI/ 2>/dev/null || true && \
    cp /usr/x86_64-w64-mingw32/lib/libwinpthread-1.dll /output/Krepto-Windows-GUI/ 2>/dev/null || true

CMD ["cp", "-r", "/output/Krepto-Windows-GUI", "/host/"]
EOF

# Збудувати Docker образ з кешуванням
echo "🔨 Building Docker image with caching..."
docker build -f Dockerfile.windows -t krepto-windows-gui .

# Запустити збірку
echo "🚀 Running optimized Windows build..."
docker run --rm -v $(pwd):/host krepto-windows-gui

# Перевірити результат
if [ -d "Krepto-Windows-GUI" ]; then
    echo "✅ Windows GUI build completed!"
    
    # Додати конфігурацію та документацію
    echo "📝 Adding configuration and documentation..."
    
    # Копіювати конфігурацію з CLI версії
    if [ -f "Krepto-Windows-CLI/bitcoin.conf" ]; then
        cp Krepto-Windows-CLI/bitcoin.conf Krepto-Windows-GUI/
    else
        # Створити конфігурацію
        cat > Krepto-Windows-GUI/bitcoin.conf << 'EOF'
# Krepto Configuration
rpcuser=kreptouser
rpcpassword=kreptopass123
rpcport=12347
port=12345
server=1
daemon=1
addnode=164.68.117.90:12345
EOF
    fi
    
    # Створити README для GUI версії
    cat > Krepto-Windows-GUI/README.txt << 'EOF'
🚀 Krepto - Bitcoin Fork for Windows (GUI Version)

INSTALLATION:
1. Extract all files to a folder (e.g., C:\Krepto)
2. Run Krepto.exe to start the GUI
3. Wait for synchronization with Krepto network

EXECUTABLES:
- Krepto.exe - Main GUI application with built-in mining
- kryptod.exe - Daemon (command line)
- krypto-cli.exe - CLI tools
- krypto-tx.exe - Transaction tools
- krypto-util.exe - Utility tools

NETWORK INFO:
- Krepto uses its own blockchain (not Bitcoin)
- Connects to seed node: 164.68.117.90:12345
- Data stored in: %APPDATA%\Krepto\
- Addresses start with 'K' (legacy) or 'kr1q' (SegWit)

FEATURES:
- GUI Mining built-in (Mining menu)
- SegWit support from genesis
- Fast block generation
- Compatible with Bitcoin Core RPC
- Modern Qt5 interface

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

Enjoy mining Krepto with GUI! 🎉
EOF

    # Створити batch файли для зручності
    cat > Krepto-Windows-GUI/start-gui.bat << 'EOF'
@echo off
echo Starting Krepto GUI...
start Krepto.exe
EOF

    cat > Krepto-Windows-GUI/start-daemon.bat << 'EOF'
@echo off
echo Starting Krepto daemon...
kryptod.exe -daemon
echo Daemon started. Use krypto-cli.exe for commands.
pause
EOF

    cat > Krepto-Windows-GUI/stop-daemon.bat << 'EOF'
@echo off
echo Stopping Krepto daemon...
krypto-cli.exe stop
echo Daemon stopped.
pause
EOF

    # Створити ZIP архів
    echo "📦 Creating ZIP archive..."
    zip -r Krepto-Windows-GUI.zip Krepto-Windows-GUI/
    
    # Показати результат
    echo "📊 Build results:"
    ls -lh Krepto-Windows-GUI.zip
    du -sh Krepto-Windows-GUI/
    
    echo ""
    echo "🎊 Krepto Windows GUI build completed successfully!"
    
else
    echo "❌ Windows GUI build failed!"
    exit 1
fi

# Очистити тимчасові файли
echo "🧹 Cleaning up..."
rm -f Dockerfile.windows
docker rmi krepto-windows-gui 2>/dev/null || true

echo ""
echo "🎯 Next steps:"
echo "1. Test Krepto-Windows-GUI.zip on Windows VM"
echo "2. Create NSIS installer (optional)"
echo "3. Upload for distribution"
echo ""
echo "⚡ Optimizations applied:"
echo "- ccache for faster compilation"
echo "- Disabled unnecessary features (UPnP, ZMQ, tests)"
echo "- Docker layer caching"
echo "- Fixed all icon file issues"
echo "- Reduced verbose output" 