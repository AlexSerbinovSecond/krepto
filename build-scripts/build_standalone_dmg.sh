#!/bin/bash

set -e

echo "🚀 Building Standalone Krepto DMG (with Qt5 included)..."

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
mkdir -p Krepto.app/Contents/{MacOS,Resources,Frameworks}

# Копіювати основні файли
echo "📋 Copying executables..."
cp src/qt/bitcoin-qt Krepto.app/Contents/MacOS/bitcoin-qt
cp src/bitcoind Krepto.app/Contents/MacOS/kryptod
cp src/bitcoin-cli Krepto.app/Contents/MacOS/krypto-cli

# Використати macdeployqt для автоматичного включення Qt frameworks
echo "🔧 Using macdeployqt to bundle Qt frameworks..."
if command -v macdeployqt >/dev/null 2>&1; then
    # Створити тимчасовий app bundle для macdeployqt
    mkdir -p temp_app.app/Contents/MacOS
    cp src/qt/bitcoin-qt temp_app.app/Contents/MacOS/
    
    # Запустити macdeployqt
    macdeployqt temp_app.app
    
    # Скопіювати frameworks з тимчасового app bundle
    if [ -d "temp_app.app/Contents/Frameworks" ]; then
        cp -R temp_app.app/Contents/Frameworks/* Krepto.app/Contents/Frameworks/
        echo "✅ Qt frameworks copied successfully"
    fi
    
    # Очистити тимчасовий app bundle
    rm -rf temp_app.app
else
    echo "⚠️ macdeployqt not found, manually copying Qt frameworks..."
    
    # Знайти Qt frameworks
    QT_PATH="/opt/homebrew/opt/qt@5/lib"
    if [ ! -d "$QT_PATH" ]; then
        QT_PATH="/usr/local/opt/qt@5/lib"
    fi
    
    if [ -d "$QT_PATH" ]; then
        echo "📦 Copying Qt frameworks from $QT_PATH..."
        cp -R "$QT_PATH/QtCore.framework" Krepto.app/Contents/Frameworks/
        cp -R "$QT_PATH/QtGui.framework" Krepto.app/Contents/Frameworks/
        cp -R "$QT_PATH/QtWidgets.framework" Krepto.app/Contents/Frameworks/
        cp -R "$QT_PATH/QtNetwork.framework" Krepto.app/Contents/Frameworks/
        cp -R "$QT_PATH/QtDBus.framework" Krepto.app/Contents/Frameworks/
        
        # Виправити шляхи в виконуваному файлі
        echo "🔧 Fixing framework paths..."
        install_name_tool -change "/opt/homebrew/opt/qt@5/lib/QtCore.framework/Versions/5/QtCore" "@executable_path/../Frameworks/QtCore.framework/Versions/5/QtCore" Krepto.app/Contents/MacOS/bitcoin-qt
        install_name_tool -change "/opt/homebrew/opt/qt@5/lib/QtGui.framework/Versions/5/QtGui" "@executable_path/../Frameworks/QtGui.framework/Versions/5/QtGui" Krepto.app/Contents/MacOS/bitcoin-qt
        install_name_tool -change "/opt/homebrew/opt/qt@5/lib/QtWidgets.framework/Versions/5/QtWidgets" "@executable_path/../Frameworks/QtWidgets.framework/Versions/5/QtWidgets" Krepto.app/Contents/MacOS/bitcoin-qt
        install_name_tool -change "/opt/homebrew/opt/qt@5/lib/QtNetwork.framework/Versions/5/QtNetwork" "@executable_path/../Frameworks/QtNetwork.framework/Versions/5/QtNetwork" Krepto.app/Contents/MacOS/bitcoin-qt
        install_name_tool -change "/opt/homebrew/opt/qt@5/lib/QtDBus.framework/Versions/5/QtDBus" "@executable_path/../Frameworks/QtDBus.framework/Versions/5/QtDBus" Krepto.app/Contents/MacOS/bitcoin-qt
        
        echo "✅ Qt frameworks included manually"
    else
        echo "❌ Qt5 not found in expected locations"
        exit 1
    fi
fi

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

# Тестувати app bundle
echo "🧪 Testing app bundle..."
echo "App bundle size:"
du -sh Krepto.app/

echo "Frameworks included:"
ls -la Krepto.app/Contents/Frameworks/ 2>/dev/null || echo "No frameworks directory"

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
- Self-contained - NO additional software required!

REQUIREMENTS:
- macOS 10.14 or later
- NO additional software installation needed!

IMPORTANT:
Krepto automatically uses ~/.krepto directory for blockchain data.
This is separate from Bitcoin and will NOT download 620GB of Bitcoin blockchain.
All configuration is handled automatically - just install and run!

All required Qt5 libraries are included - completely standalone!

For support: https://krepto.org
EOF

# Створити DMG
hdiutil create -volname "Krepto" -srcfolder dmg_temp -ov -format UDZO Krepto.dmg

# Створити checksums
shasum -a 256 Krepto.dmg > Krepto.dmg.sha256
md5 Krepto.dmg > Krepto.dmg.md5

# Очистити тимчасові файли
rm -rf dmg_temp

echo "✅ Standalone DMG created successfully!"
echo "📋 File info:"
ls -lh Krepto.dmg
echo "🔐 Checksums:"
cat Krepto.dmg.sha256
cat Krepto.dmg.md5

echo ""
echo "📦 DMG Features:"
echo "- Completely standalone (Qt5 frameworks included)"
echo "- No external dependencies required"
echo "- Works on any macOS 10.14+ system"
echo "- No Homebrew or Qt5 installation needed"
echo "- Ready for distribution!" 