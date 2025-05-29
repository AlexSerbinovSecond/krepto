#!/bin/bash

# Krepto Windows GUI Build Script - Simple Approach
# Bypasses the complex depends system and uses system Qt5

set -e

echo "🚀 Krepto Windows GUI Build - Simple Approach"
echo "=============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
HOST="x86_64-w64-mingw32"
NCPU=$(sysctl -n hw.ncpu)
BUILD_DIR="$(pwd)"

echo -e "${BLUE}Configuration:${NC}"
echo "  HOST: $HOST"
echo "  CPU cores: $NCPU"
echo "  Build directory: $BUILD_DIR"

# Step 1: Verify MinGW toolchain
echo -e "\n${YELLOW}Step 1: Verifying MinGW toolchain...${NC}"
if ! command -v ${HOST}-gcc &> /dev/null; then
    echo -e "${RED}❌ MinGW toolchain not found. Installing...${NC}"
    brew install mingw-w64
fi

echo -e "${GREEN}✅ MinGW toolchain found${NC}"
${HOST}-gcc --version | head -1

# Step 2: Clean previous builds
echo -e "\n${YELLOW}Step 2: Cleaning previous builds...${NC}"
make distclean 2>/dev/null || true
rm -rf src/qt/bitcoin-qt.exe src/bitcoind.exe src/bitcoin-cli.exe 2>/dev/null || true
echo -e "${GREEN}✅ Clean completed${NC}"

# Step 3: Configure for Windows without Qt (CLI only first)
echo -e "\n${YELLOW}Step 3: Configuring for Windows CLI build...${NC}"

# Set environment variables for cross-compilation
export CC="${HOST}-gcc"
export CXX="${HOST}-g++"
export AR="${HOST}-ar"
export RANLIB="${HOST}-ranlib"
export STRIP="${HOST}-strip"
export PKG_CONFIG_PATH=""
export PKG_CONFIG_LIBDIR=""

# Configure without GUI first to test basic cross-compilation
./autogen.sh
./configure \
    --prefix=/tmp/krepto-windows \
    --host=${HOST} \
    --disable-shared \
    --enable-static \
    --disable-tests \
    --disable-bench \
    --disable-gui \
    --with-incompatible-bdb \
    --disable-wallet \
    --disable-zmq \
    --disable-debug \
    CFLAGS="-O2 -pipe" \
    CXXFLAGS="-O2 -pipe" \
    LDFLAGS="-static-libgcc -static-libstdc++"

echo -e "${GREEN}✅ Configuration completed${NC}"

# Step 4: Build CLI tools
echo -e "\n${YELLOW}Step 4: Building CLI tools...${NC}"
make -j${NCPU}

if [ -f "src/bitcoind" ]; then
    echo -e "${GREEN}✅ CLI build successful${NC}"
else
    echo -e "${RED}❌ CLI build failed${NC}"
    exit 1
fi

# Step 5: Test if basic cross-compilation works
echo -e "\n${YELLOW}Step 5: Testing cross-compilation...${NC}"
file src/bitcoind
file src/bitcoin-cli

# Step 6: Now try with GUI (if CLI worked)
echo -e "\n${YELLOW}Step 6: Attempting GUI build...${NC}"

# Clean and reconfigure with GUI
make distclean

# Try to find Qt5 for MinGW
QT5_PREFIX=""
if [ -d "/opt/homebrew/opt/qt@5" ]; then
    QT5_PREFIX="/opt/homebrew/opt/qt@5"
elif [ -d "/usr/local/opt/qt@5" ]; then
    QT5_PREFIX="/usr/local/opt/qt@5"
fi

if [ -n "$QT5_PREFIX" ]; then
    echo "Found Qt5 at: $QT5_PREFIX"
    
    # Set Qt5 environment
    export PKG_CONFIG_PATH="$QT5_PREFIX/lib/pkgconfig:$PKG_CONFIG_PATH"
    export Qt5_DIR="$QT5_PREFIX/lib/cmake/Qt5"
    
    # Try configure with GUI
    ./configure \
        --prefix=/tmp/krepto-windows \
        --host=${HOST} \
        --disable-shared \
        --enable-static \
        --disable-tests \
        --disable-bench \
        --enable-gui \
        --with-incompatible-bdb \
        --disable-wallet \
        --disable-zmq \
        --disable-debug \
        --with-qt-bindir="$QT5_PREFIX/bin" \
        --with-qt-libdir="$QT5_PREFIX/lib" \
        --with-qt-incdir="$QT5_PREFIX/include" \
        CFLAGS="-O2 -pipe" \
        CXXFLAGS="-O2 -pipe" \
        LDFLAGS="-static-libgcc -static-libstdc++"
    
    echo -e "\n${YELLOW}Building with GUI...${NC}"
    make -j${NCPU}
    
    if [ -f "src/qt/bitcoin-qt" ]; then
        echo -e "${GREEN}✅ GUI build successful!${NC}"
        
        # Step 7: Create distribution package
        echo -e "\n${YELLOW}Step 7: Creating distribution package...${NC}"
        
        DIST_DIR="Krepto-Windows-GUI-Simple"
        rm -rf "$DIST_DIR"
        mkdir -p "$DIST_DIR"
        
        # Copy executables with proper naming
        cp src/bitcoind "$DIST_DIR/kryptod.exe"
        cp src/bitcoin-cli "$DIST_DIR/krepto-cli.exe"
        cp src/qt/bitcoin-qt "$DIST_DIR/krepto-qt.exe"
        
        # Copy additional tools if they exist
        [ -f "src/bitcoin-tx" ] && cp src/bitcoin-tx "$DIST_DIR/krepto-tx.exe"
        [ -f "src/bitcoin-util" ] && cp src/bitcoin-util "$DIST_DIR/krepto-util.exe"
        [ -f "src/bitcoin-wallet" ] && cp src/bitcoin-wallet "$DIST_DIR/krepto-wallet.exe"
        
        # Create configuration file
        cat > "$DIST_DIR/bitcoin.conf" << EOF
# Krepto Configuration File
# Network settings
port=12345
rpcport=12347

# Seed nodes
addnode=164.68.117.90:12345
addnode=5.189.133.204:12345

# Basic settings
server=1
daemon=1
txindex=1

# RPC settings
rpcuser=kreptouser
rpcpassword=kreptopass123
rpcallowip=127.0.0.1
EOF
        
        # Create README
        cat > "$DIST_DIR/README.txt" << EOF
Krepto Windows GUI Distribution
==============================

This package contains the Krepto cryptocurrency GUI and CLI tools for Windows.

Files included:
- krepto-qt.exe     : Graphical user interface
- kryptod.exe       : Daemon/server
- krepto-cli.exe    : Command line interface
- krepto-tx.exe     : Transaction utility
- krepto-util.exe   : General utility
- krepto-wallet.exe : Wallet utility
- bitcoin.conf      : Configuration file

To start the GUI:
1. Double-click krepto-qt.exe

To start the daemon:
1. Open Command Prompt
2. Navigate to this folder
3. Run: kryptod.exe

Network Information:
- Main network port: 12345
- RPC port: 12347
- Seed nodes: 164.68.117.90:12345, 5.189.133.204:12345

For more information, visit: https://krepto.org
EOF
        
        # Create ZIP package
        zip -r "${DIST_DIR}.zip" "$DIST_DIR"
        
        # Calculate checksums
        echo -e "\n${GREEN}✅ Distribution package created successfully!${NC}"
        echo -e "${BLUE}Package details:${NC}"
        echo "  File: ${DIST_DIR}.zip"
        echo "  Size: $(du -h "${DIST_DIR}.zip" | cut -f1)"
        echo "  SHA256: $(shasum -a 256 "${DIST_DIR}.zip" | cut -d' ' -f1)"
        echo "  MD5: $(md5 -q "${DIST_DIR}.zip")"
        
        echo -e "\n${GREEN}🎉 Windows GUI build completed successfully!${NC}"
        echo -e "${BLUE}Files ready for distribution:${NC}"
        ls -la "$DIST_DIR"
        
    else
        echo -e "${RED}❌ GUI build failed${NC}"
        echo "Checking for Qt5 cross-compilation issues..."
        
        # Show configuration summary
        echo -e "\n${YELLOW}Configuration summary:${NC}"
        grep -A 20 -B 5 "Qt" config.log | tail -30 || true
    fi
else
    echo -e "${RED}❌ Qt5 not found. GUI build skipped.${NC}"
    echo "Install Qt5 with: brew install qt@5"
fi

echo -e "\n${BLUE}Build process completed.${NC}" 