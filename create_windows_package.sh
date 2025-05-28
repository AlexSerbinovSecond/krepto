#!/bin/bash

set -e

echo "🪟 Creating Krepto Windows Package..."

# Створити директорію для пакету
PACKAGE_DIR="Krepto-Windows-GUI"
rm -rf "$PACKAGE_DIR"
mkdir -p "$PACKAGE_DIR"

echo "📁 Created package directory: $PACKAGE_DIR"

# Копіювати та перейменувати виконувані файли
echo "📋 Copying and renaming executables..."
cp src/bitcoind.exe "$PACKAGE_DIR/kryptod.exe"
cp src/bitcoin-cli.exe "$PACKAGE_DIR/krepto-cli.exe"
cp src/bitcoin-tx.exe "$PACKAGE_DIR/krepto-tx.exe"
cp src/bitcoin-util.exe "$PACKAGE_DIR/krepto-util.exe"
cp src/bitcoin-wallet.exe "$PACKAGE_DIR/krepto-wallet.exe"

echo "✅ Executables copied and renamed:"
echo "  - kryptod.exe (daemon)"
echo "  - krepto-cli.exe (CLI interface)"
echo "  - krepto-tx.exe (transaction utility)"
echo "  - krepto-util.exe (utility tool)"
echo "  - krepto-wallet.exe (wallet tool)"

# Створити конфігураційний файл
echo "⚙️ Creating bitcoin.conf..."
cat > "$PACKAGE_DIR/bitcoin.conf" << 'EOF'
# Krepto Configuration File
# Network settings
port=12345
rpcport=12347
rpcuser=kreptouser
rpcpassword=kreptopass123
rpcallowip=127.0.0.1

# Seed nodes
addnode=164.68.117.90:12345
addnode=5.189.133.204:12345
connect=164.68.117.90:12345
connect=5.189.133.204:12345

# Performance settings
maxconnections=50
timeout=30000

# Logging
debug=1
printtoconsole=0

# Mining settings (optional)
gen=0
genproclimit=1

# Wallet settings
disablewallet=0
EOF

# Створити batch файли для зручності
echo "📝 Creating batch files..."

# Start daemon
cat > "$PACKAGE_DIR/start-daemon.bat" << 'EOF'
@echo off
echo Starting Krepto Daemon...
kryptod.exe -datadir=data -conf=bitcoin.conf
pause
EOF

# Stop daemon
cat > "$PACKAGE_DIR/stop-daemon.bat" << 'EOF'
@echo off
echo Stopping Krepto Daemon...
krepto-cli.exe -datadir=data -conf=bitcoin.conf stop
pause
EOF

# Get info
cat > "$PACKAGE_DIR/get-info.bat" << 'EOF'
@echo off
echo Getting Krepto Network Info...
krepto-cli.exe -datadir=data -conf=bitcoin.conf getblockchaininfo
echo.
echo Getting Wallet Info...
krepto-cli.exe -datadir=data -conf=bitcoin.conf getwalletinfo
pause
EOF

# Create wallet
cat > "$PACKAGE_DIR/create-wallet.bat" << 'EOF'
@echo off
echo Creating Krepto Wallet...
krepto-cli.exe -datadir=data -conf=bitcoin.conf createwallet "main"
echo.
echo Getting new address...
krepto-cli.exe -datadir=data -conf=bitcoin.conf getnewaddress
pause
EOF

# Start mining
cat > "$PACKAGE_DIR/start-mining.bat" << 'EOF'
@echo off
echo Starting Krepto Mining...
echo Please enter your Krepto address:
set /p ADDRESS=Address: 
krepto-cli.exe -datadir=data -conf=bitcoin.conf generatetoaddress 1 %ADDRESS% 10000000
pause
EOF

# Створити README
echo "📖 Creating README.txt..."
cat > "$PACKAGE_DIR/README.txt" << 'EOF'
===========================================
    KREPTO - Windows CLI Distribution
===========================================

OVERVIEW:
Krepto is a Bitcoin-based cryptocurrency with fast mining and SegWit support.
This package contains all necessary tools to run Krepto on Windows.

INCLUDED FILES:
- kryptod.exe         : Main daemon (server)
- krepto-cli.exe      : Command line interface
- krepto-tx.exe       : Transaction utility
- krepto-util.exe     : General utility tool
- krepto-wallet.exe   : Wallet management tool
- bitcoin.conf        : Configuration file
- *.bat files         : Convenience scripts

QUICK START:
1. Double-click "start-daemon.bat" to start the Krepto daemon
2. Wait for synchronization with the network
3. Double-click "create-wallet.bat" to create your wallet
4. Use "get-info.bat" to check status
5. Use "start-mining.bat" to mine Krepto coins

NETWORK DETAILS:
- Network Port: 12345
- RPC Port: 12347
- Seed Nodes: 164.68.117.90:12345, 5.189.133.204:12345
- Data Directory: ./data/

MANUAL COMMANDS:
Start daemon:
  kryptod.exe -datadir=data -conf=bitcoin.conf

Get blockchain info:
  krepto-cli.exe -datadir=data -conf=bitcoin.conf getblockchaininfo

Create wallet:
  krepto-cli.exe -datadir=data -conf=bitcoin.conf createwallet "main"

Get new address:
  krepto-cli.exe -datadir=data -conf=bitcoin.conf getnewaddress

Mine blocks:
  krepto-cli.exe -datadir=data -conf=bitcoin.conf generatetoaddress 1 [YOUR_ADDRESS] 10000000

Stop daemon:
  krepto-cli.exe -datadir=data -conf=bitcoin.conf stop

SUPPORT:
For technical support and updates, visit the Krepto community.

===========================================
EOF

# Створити директорію для даних
mkdir -p "$PACKAGE_DIR/data"

echo "📦 Creating ZIP archive..."
zip -r "Krepto-Windows-GUI.zip" "$PACKAGE_DIR/"

echo "✅ Package created successfully!"
echo "📁 Directory: $PACKAGE_DIR/"
echo "📦 Archive: Krepto-Windows-GUI.zip"
echo ""
echo "📊 Package contents:"
ls -la "$PACKAGE_DIR/"
echo ""
echo "📏 Archive size:"
ls -lh "Krepto-Windows-GUI.zip" 