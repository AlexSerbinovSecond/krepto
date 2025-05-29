#!/bin/bash

set -e

echo "🚀 Building Simple Krepto DMG (for testing)..."

# Очистити попередні збірки
rm -rf Krepto.app dmg_temp Krepto.dmg

# Перевірити чи є виконувані файли
if [ ! -f "src/qt/bitcoin-qt" ] || [ ! -f "src/bitcoind" ] || [ ! -f "src/bitcoin-cli" ]; then
    echo "❌ Executable files not found!"
    exit 1
fi

# Створити app bundle
echo "📱 Creating simple app bundle..."
mkdir -p Krepto.app/Contents/{MacOS,Resources}

# Копіювати основні файли
echo "📋 Copying executables..."
cp src/qt/bitcoin-qt Krepto.app/Contents/MacOS/bitcoin-qt
cp src/bitcoind Krepto.app/Contents/MacOS/kryptod
cp src/bitcoin-cli Krepto.app/Contents/MacOS/krypto-cli

# Створити wrapper скрипт
echo "📝 Creating wrapper script..."
cat > Krepto.app/Contents/MacOS/Krepto << 'EOF'
#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Set Krepto data directory
KREPTO_DATADIR="$HOME/.krepto"

# Create datadir if it doesn't exist
mkdir -p "$KREPTO_DATADIR"

# Copy default config if it doesn't exist
if [ ! -f "$KREPTO_DATADIR/bitcoin.conf" ]; then
    cp "$SCRIPT_DIR/../Resources/bitcoin.conf" "$KREPTO_DATADIR/" 2>/dev/null || true
fi

# Launch Krepto with correct datadir
exec "$SCRIPT_DIR/bitcoin-qt" -datadir="$KREPTO_DATADIR" "$@"
EOF

chmod +x Krepto.app/Contents/MacOS/*

# Створити Info.plist
echo "📄 Creating Info.plist..."
cat > Krepto.app/Contents/Info.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Krepto</string>
    <key>CFBundleIdentifier</key>
    <string>org.krepto.Krepto</string>
    <key>CFBundleName</key>
    <string>Krepto</string>
    <key>CFBundleDisplayName</key>
    <string>Krepto</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleSignature</key>
    <string>KREP</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.14</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

# Створити конфігурацію
echo "⚙️ Creating configuration..."
cat > Krepto.app/Contents/Resources/bitcoin.conf << 'EOF'
# Krepto Default Configuration
port=12345
rpcport=12347
server=1
rpcuser=kreptouser
rpcpassword=kreptopass123
gui=1
gen=0
listen=1
discover=1
deprecatedrpc=generate
dbcache=512
maxmempool=300
debug=0
printtoconsole=0
EOF

# Тестувати app bundle
echo "🧪 Testing app bundle..."
ls -la Krepto.app/Contents/MacOS/
echo "Testing wrapper script..."
./Krepto.app/Contents/MacOS/Krepto --version

echo "✅ Simple app bundle created successfully!"
echo "📋 Size:"
du -sh Krepto.app/ 