#!/bin/bash

# Krepto Windows CLI Build Script - Working Version
# Focus on CLI tools first, then attempt GUI

set -e

echo "🚀 Krepto Windows CLI Build"
echo "==========================="

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
rm -rf src/bitcoind.exe src/bitcoin-cli.exe 2>/dev/null || true
echo -e "${GREEN}✅ Clean completed${NC}"

# Step 3: Set environment for cross-compilation
echo -e "\n${YELLOW}Step 3: Setting up cross-compilation environment...${NC}"

# Set environment variables for cross-compilation
export CC="${HOST}-gcc"
export CXX="${HOST}-g++"
export AR="${HOST}-ar"
export RANLIB="${HOST}-ranlib"
export STRIP="${HOST}-strip"
export PKG_CONFIG_PATH=""
export PKG_CONFIG_LIBDIR=""

# Find libevent and boost
LIBEVENT_PREFIX="/opt/homebrew"
BOOST_PREFIX="/opt/homebrew"

echo "Using libevent from: $LIBEVENT_PREFIX"
echo "Using boost from: $BOOST_PREFIX"

# Step 4: Configure for Windows CLI build
echo -e "\n${YELLOW}Step 4: Configuring for Windows CLI build...${NC}"

./autogen.sh

# Configure with explicit paths
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
    --disable-fuzz-binary \
    --disable-ccache \
    --disable-maintainer-mode \
    --with-boost="$BOOST_PREFIX" \
    --with-libevent="$LIBEVENT_PREFIX" \
    CFLAGS="-O2 -pipe -I$LIBEVENT_PREFIX/include -I$BOOST_PREFIX/include" \
    CXXFLAGS="-O2 -pipe -I$LIBEVENT_PREFIX/include -I$BOOST_PREFIX/include" \
    LDFLAGS="-static-libgcc -static-libstdc++ -L$LIBEVENT_PREFIX/lib -L$BOOST_PREFIX/lib" \
    LIBS="-levent -lboost_system -lboost_filesystem -lboost_thread -lpthread"

echo -e "${GREEN}✅ Configuration completed${NC}"

# Step 5: Build CLI tools
echo -e "\n${YELLOW}Step 5: Building CLI tools...${NC}"
make -j${NCPU}

if [ -f "src/bitcoind" ]; then
    echo -e "${GREEN}✅ CLI build successful${NC}"
else
    echo -e "${RED}❌ CLI build failed${NC}"
    echo "Checking config.log for errors..."
    tail -50 config.log
    exit 1
fi

# Step 6: Test executables
echo -e "\n${YELLOW}Step 6: Testing executables...${NC}"
file src/bitcoind
file src/bitcoin-cli

# Check if they're Windows executables
if file src/bitcoind | grep -q "PE32+"; then
    echo -e "${GREEN}✅ Windows executables created successfully${NC}"
else
    echo -e "${RED}❌ Not Windows executables${NC}"
    exit 1
fi

# Step 7: Create distribution package
echo -e "\n${YELLOW}Step 7: Creating distribution package...${NC}"

DIST_DIR="Krepto-Windows-CLI-Working"
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

# Copy executables with proper naming
cp src/bitcoind "$DIST_DIR/kryptod.exe"
cp src/bitcoin-cli "$DIST_DIR/krepto-cli.exe"

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

# Create batch files for easy startup
cat > "$DIST_DIR/start-daemon.bat" << EOF
@echo off
echo Starting Krepto Daemon...
kryptod.exe
pause
EOF

cat > "$DIST_DIR/start-cli.bat" << EOF
@echo off
echo Krepto CLI Interface
echo Type 'help' for available commands
krepto-cli.exe
pause
EOF

# Create README
cat > "$DIST_DIR/README.txt" << EOF
Krepto Windows CLI Distribution
==============================

This package contains the Krepto cryptocurrency CLI tools for Windows.

Files included:
- kryptod.exe       : Daemon/server
- krepto-cli.exe    : Command line interface
- krepto-tx.exe     : Transaction utility
- krepto-util.exe   : General utility
- krepto-wallet.exe : Wallet utility
- bitcoin.conf      : Configuration file
- start-daemon.bat  : Easy daemon startup
- start-cli.bat     : Easy CLI startup

Quick Start:
1. Double-click start-daemon.bat to start the daemon
2. Wait for synchronization to complete
3. Double-click start-cli.bat to use CLI commands

Network Information:
- Main network port: 12345
- RPC port: 12347
- Seed nodes: 164.68.117.90:12345, 5.189.133.204:12345
- Data directory: %APPDATA%\\Krepto\\

Common Commands:
- krepto-cli.exe getblockchaininfo
- krepto-cli.exe getpeerinfo
- krepto-cli.exe getnewaddress
- krepto-cli.exe generatetoaddress 1 <address>

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

echo -e "\n${GREEN}🎉 Windows CLI build completed successfully!${NC}"
echo -e "${BLUE}Files ready for distribution:${NC}"
ls -la "$DIST_DIR"

echo -e "\n${YELLOW}Next steps:${NC}"
echo "1. Test the CLI tools on a Windows machine"
echo "2. If CLI works, we can attempt GUI build with different approach"
echo "3. Consider using Docker for Qt5 cross-compilation"

echo -e "\n${BLUE}Build process completed.${NC}" 