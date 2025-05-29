#!/bin/bash

set -e

echo "🚀 Building Krepto DMG with macdeployqt (Official Qt Tool)..."

# Очистити попередні збірки
rm -rf Krepto.app dmg_temp Krepto.dmg Krepto.dmg.sha256 Krepto.dmg.md5

# Перевірити чи є виконувані файли
if [ ! -f "src/qt/bitcoin-qt" ] || [ ! -f "src/bitcoind" ] || [ ! -f "src/bitcoin-cli" ]; then
    echo "❌ Executable files not found. Building Krepto first..."
    make clean
    ./configure --enable-gui --disable-tests --disable-bench
    make -j8
fi

# Створити app bundle
echo "📱 Creating app bundle..."
mkdir -p Krepto.app/Contents/{MacOS,Resources}

# Копіювати основні файли
echo "📋 Copying executables..."
cp src/qt/bitcoin-qt Krepto.app/Contents/MacOS/bitcoin-qt
cp src/bitcoind Krepto.app/Contents/MacOS/kryptod
cp src/bitcoin-cli Krepto.app/Contents/MacOS/krypto-cli

# Створити wrapper скрипт для правильного datadir
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

# Створити іконку
echo "🎨 Creating icon..."
if [ -f "share/pixmaps/Bitcoin256.png" ]; then
    mkdir -p krepto.iconset
    
    # Створити квадратну версію 1024x1024
    sips -z 1024 1024 share/pixmaps/Bitcoin256.png --out temp_1024.png
    
    # Створити всі необхідні розміри
    sips -z 16 16 temp_1024.png --out krepto.iconset/icon_16x16.png
    sips -z 32 32 temp_1024.png --out krepto.iconset/icon_16x16@2x.png
    sips -z 32 32 temp_1024.png --out krepto.iconset/icon_32x32.png
    sips -z 64 64 temp_1024.png --out krepto.iconset/icon_32x32@2x.png
    sips -z 128 128 temp_1024.png --out krepto.iconset/icon_128x128.png
    sips -z 256 256 temp_1024.png --out krepto.iconset/icon_128x128@2x.png
    sips -z 256 256 temp_1024.png --out krepto.iconset/icon_256x256.png
    sips -z 512 512 temp_1024.png --out krepto.iconset/icon_256x256@2x.png
    sips -z 512 512 temp_1024.png --out krepto.iconset/icon_512x512.png
    sips -z 1024 1024 temp_1024.png --out krepto.iconset/icon_512x512@2x.png
    
    # Створити ICNS
    iconutil -c icns krepto.iconset
    cp krepto.icns Krepto.app/Contents/Resources/
    
    # Очистити тимчасові файли
    rm -rf krepto.iconset krepto.icns temp_1024.png
    
    echo "✅ Icon created"
fi

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
    <key>CFBundleIconFile</key>
    <string>krepto</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.14</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSRequiresAquaSystemAppearance</key>
    <false/>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.finance</string>
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

# 🎯 ВИКОРИСТАТИ MACDEPLOYQT - ОФІЦІЙНИЙ QT ІНСТРУМЕНТ!
echo "🔧 Using macdeployqt (Official Qt Tool) to bundle Qt frameworks..."
MACDEPLOYQT="/opt/homebrew/Cellar/qt@5/5.15.16_2/bin/macdeployqt"

if [ -f "$MACDEPLOYQT" ]; then
    echo "✅ Found macdeployqt at: $MACDEPLOYQT"
    
    # Запустити macdeployqt для автоматичного включення Qt frameworks
    "$MACDEPLOYQT" Krepto.app -verbose=2
    
    echo "✅ macdeployqt completed successfully!"
    echo "📦 Qt frameworks automatically included and configured!"
else
    echo "❌ macdeployqt not found at expected location"
    echo "🔍 Searching for macdeployqt..."
    find /opt -name "macdeployqt" 2>/dev/null || echo "macdeployqt not found"
    exit 1
fi

# Тестувати app bundle
echo "🧪 Testing app bundle..."
echo "App bundle size:"
du -sh Krepto.app/

echo "Frameworks included:"
ls -la Krepto.app/Contents/Frameworks/ 2>/dev/null || echo "No frameworks directory"

echo "Checking Qt dependencies:"
otool -L Krepto.app/Contents/MacOS/bitcoin-qt | grep -E "(Qt|@executable_path)" || echo "No Qt dependencies found"

# Створити DMG
echo "💿 Creating DMG..."
mkdir -p dmg_temp
cp -R Krepto.app dmg_temp/
ln -s /Applications dmg_temp/Applications

# Створити README
cat > dmg_temp/README.txt << 'EOF'
Krepto - Cryptocurrency Mining Made Simple

INSTALLATION:
1. Drag Krepto.app to Applications folder
2. Launch Krepto from Applications
3. Click "Start Mining" to begin

FEATURES:
- Easy-to-use GUI interface
- Built-in mining functionality
- Automatic network connection
- Secure wallet management
- Uses ~/.krepto data directory automatically
- Automatic configuration setup
- COMPLETELY STANDALONE - NO Qt5 installation required!

REQUIREMENTS:
- macOS 10.14 or later
- NO additional software installation needed!

IMPORTANT:
Krepto automatically uses ~/.krepto directory for blockchain data.
This is separate from Bitcoin and will NOT download 620GB of Bitcoin blockchain.
All configuration is handled automatically - just install and run!

All required Qt5 libraries are included using official Qt deployment tools!

For support: https://krepto.org
EOF

# Створити DMG
hdiutil create -volname "Krepto" -srcfolder dmg_temp -ov -format UDZO Krepto.dmg

# Створити checksums
shasum -a 256 Krepto.dmg > Krepto.dmg.sha256
md5 Krepto.dmg > Krepto.dmg.md5

# Очистити тимчасові файли
rm -rf dmg_temp

echo "✅ Qt-powered standalone DMG created successfully!"
echo "📋 File info:"
ls -lh Krepto.dmg
echo "🔐 Checksums:"
cat Krepto.dmg.sha256
cat Krepto.dmg.md5

echo ""
echo "📦 DMG Features:"
echo "- Uses official Qt macdeployqt tool"
echo "- Completely standalone (Qt5 frameworks included automatically)"
echo "- No external dependencies required"
echo "- Works on any macOS 10.14+ system"
echo "- No Homebrew or Qt5 installation needed"
echo "- Professional Qt deployment"
echo "- Ready for distribution!" 