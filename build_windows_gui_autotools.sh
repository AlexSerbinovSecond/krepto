#!/bin/bash

# Krepto Windows Bitcoin Qt GUI Build - Autotools Approach
# Simplified approach using autotools instead of depends system

set -e

echo "🚀 Krepto Windows Bitcoin Qt GUI Build - Autotools"
echo "=================================================="

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

# Step 2: Install required dependencies via Homebrew
echo -e "\n${YELLOW}Step 2: Installing dependencies...${NC}"

# Install Qt5 if not present
if ! brew list qt@5 &>/dev/null; then
    echo "Installing Qt5..."
    brew install qt@5
fi

# Install other dependencies
brew install autoconf automake libtool pkg-config boost libevent openssl@3

echo -e "${GREEN}✅ Dependencies installed${NC}"

# Step 3: Clean previous builds
echo -e "\n${YELLOW}Step 3: Cleaning previous builds...${NC}"
make distclean 2>/dev/null || true
rm -rf src/qt/bitcoin-qt src/bitcoind src/bitcoin-cli 2>/dev/null || true
echo -e "${GREEN}✅ Clean completed${NC}"

# Step 4: Try simple approach without depends system
echo -e "\n${YELLOW}Step 4: Configuring without depends system...${NC}"

# Set environment for cross-compilation
export CC="${HOST}-gcc"
export CXX="${HOST}-g++"
export AR="${HOST}-ar"
export RANLIB="${HOST}-ranlib"
export STRIP="${HOST}-strip"

# Find Qt5 installation
QT5_PREFIX="/opt/homebrew/opt/qt@5"
if [ ! -d "$QT5_PREFIX" ]; then
    QT5_PREFIX="/usr/local/opt/qt@5"
fi

if [ ! -d "$QT5_PREFIX" ]; then
    echo -e "${RED}❌ Qt5 not found${NC}"
    exit 1
fi

echo "Using Qt5 from: $QT5_PREFIX"

# Generate configure script
./autogen.sh

# Try configure with minimal options
echo -e "\n${YELLOW}Attempting minimal configuration...${NC}"

./configure \
    --prefix=/tmp/krepto-windows \
    --host=${HOST} \
    --disable-shared \
    --enable-static \
    --disable-tests \
    --disable-bench \
    --disable-gui \
    --disable-wallet \
    --disable-zmq \
    --disable-debug \
    --with-boost=/opt/homebrew \
    --with-libevent=/opt/homebrew \
    CFLAGS="-O2 -pipe" \
    CXXFLAGS="-O2 -pipe" \
    LDFLAGS="-static-libgcc -static-libstdc++"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Basic configuration successful${NC}"
    
    # Step 5: Build CLI tools first
    echo -e "\n${YELLOW}Step 5: Building CLI tools...${NC}"
    make -j${NCPU}
    
    if [ -f "src/bitcoind" ]; then
        echo -e "${GREEN}✅ CLI build successful${NC}"
        
        # Test the executables
        file src/bitcoind
        file src/bitcoin-cli
        
        # Step 6: Now try to add GUI support
        echo -e "\n${YELLOW}Step 6: Attempting GUI build...${NC}"
        
        # Clean and reconfigure with GUI
        make distclean
        
        # Try configure with GUI but using system Qt5
        ./configure \
            --prefix=/tmp/krepto-windows \
            --host=${HOST} \
            --disable-shared \
            --enable-static \
            --disable-tests \
            --disable-bench \
            --enable-gui \
            --with-gui=qt5 \
            --disable-wallet \
            --disable-zmq \
            --disable-debug \
            --with-boost=/opt/homebrew \
            --with-libevent=/opt/homebrew \
            --with-qt-bindir="$QT5_PREFIX/bin" \
            --with-qt-libdir="$QT5_PREFIX/lib" \
            --with-qt-incdir="$QT5_PREFIX/include" \
            PKG_CONFIG_PATH="$QT5_PREFIX/lib/pkgconfig" \
            CFLAGS="-O2 -pipe" \
            CXXFLAGS="-O2 -pipe" \
            LDFLAGS="-static-libgcc -static-libstdc++"
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ GUI configuration successful${NC}"
            
            # Build with GUI
            make -j${NCPU}
            
            if [ -f "src/qt/bitcoin-qt" ]; then
                echo -e "${GREEN}🎉 GUI build successful!${NC}"
                
                # Step 7: Create distribution package
                echo -e "\n${YELLOW}Step 7: Creating distribution package...${NC}"
                
                DIST_DIR="Krepto-Windows-GUI-Autotools"
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
                
                # Try to copy Qt5 DLLs (this might not work for cross-compilation)
                echo "Attempting to copy Qt5 dependencies..."
                
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
Krepto Windows GUI Distribution (Autotools Build)
=================================================

This package contains the Krepto cryptocurrency GUI and CLI tools for Windows.

Files included:
- krepto-qt.exe     : Graphical user interface (Bitcoin Qt GUI)
- kryptod.exe       : Daemon/server
- krepto-cli.exe    : Command line interface
- krepto-tx.exe     : Transaction utility
- krepto-util.exe   : General utility
- krepto-wallet.exe : Wallet utility
- bitcoin.conf      : Configuration file

IMPORTANT NOTE:
This build was created using cross-compilation from macOS.
Qt5 DLLs are NOT included and must be installed separately on Windows.

To run on Windows:
1. Install Qt5 runtime libraries
2. Double-click krepto-qt.exe to start the GUI

Network Information:
- Main network port: 12345
- RPC port: 12347
- Seed nodes: 164.68.117.90:12345, 5.189.133.204:12345
- Data directory: %APPDATA%\Krepto\

For more information, visit: https://krepto.org
Built with Bitcoin Core Qt GUI technology.
EOF
                
                # Create ZIP package
                zip -r "${DIST_DIR}.zip" "$DIST_DIR"
                
                # Calculate checksums
                echo -e "\n${GREEN}✅ Distribution package created!${NC}"
                echo -e "${BLUE}Package details:${NC}"
                echo "  File: ${DIST_DIR}.zip"
                echo "  Size: $(du -h "${DIST_DIR}.zip" | cut -f1)"
                echo "  SHA256: $(shasum -a 256 "${DIST_DIR}.zip" | cut -d' ' -f1)"
                echo "  MD5: $(md5 -q "${DIST_DIR}.zip")"
                
                echo -e "\n${GREEN}🎉 Windows GUI build completed!${NC}"
                echo -e "${YELLOW}Note: This is a cross-compiled build. Qt5 DLLs need to be added manually.${NC}"
                echo -e "${BLUE}Files ready:${NC}"
                ls -la "$DIST_DIR"
                
            else
                echo -e "${RED}❌ GUI build failed${NC}"
                echo "Checking for Qt5 issues..."
                tail -50 config.log | grep -i qt || true
            fi
        else
            echo -e "${RED}❌ GUI configuration failed${NC}"
            echo "Checking config.log for Qt5 issues..."
            tail -50 config.log | grep -i qt || true
        fi
    else
        echo -e "${RED}❌ CLI build failed${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ Basic configuration failed${NC}"
    echo "Checking config.log for errors..."
    tail -50 config.log
    exit 1
fi

echo -e "\n${BLUE}Autotools build process completed.${NC}" 