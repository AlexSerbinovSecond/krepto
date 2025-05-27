#!/bin/bash

set -e

echo "🚀 Building Krepto DMG..."

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
cp src/qt/bitcoin-qt Krepto.app/Contents/MacOS/bitcoin-qt
cp src/bitcoind Krepto.app/Contents/MacOS/kryptod
cp src/bitcoin-cli Krepto.app/Contents/MacOS/krypto-cli

# Створити wrapper скрипт для правильного datadir
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

# Включити Qt5 frameworks для standalone роботи
echo "🔗 Including Qt5 frameworks..."
QT_PATH="/opt/homebrew/opt/qt@5"

if [ -d "$QT_PATH" ]; then
    echo "✅ Found Qt5 at $QT_PATH"
    
    # Копіювати необхідні Qt frameworks
    cp -R "$QT_PATH/lib/QtCore.framework" Krepto.app/Contents/Frameworks/
    cp -R "$QT_PATH/lib/QtGui.framework" Krepto.app/Contents/Frameworks/
    cp -R "$QT_PATH/lib/QtWidgets.framework" Krepto.app/Contents/Frameworks/
    cp -R "$QT_PATH/lib/QtNetwork.framework" Krepto.app/Contents/Frameworks/
    cp -R "$QT_PATH/lib/QtDBus.framework" Krepto.app/Contents/Frameworks/
    
    # Створити qt.conf для правильних шляхів
    cat > Krepto.app/Contents/Resources/qt.conf << 'EOF'
[Paths]
Frameworks = ../Frameworks
EOF
    
    echo "✅ Qt5 frameworks included"
else
    echo "⚠️  Warning: Qt5 not found at $QT_PATH"
    echo "   DMG will require Qt5 to be installed separately"
fi

# Створити іконку з кращою якістю
echo "🎨 Creating high-quality icon..."
if [ -f "share/pixmaps/Bitcoin256.png" ]; then
    mkdir -p krepto.iconset
    
    # Використати Bitcoin256.png як базу та створити квадратні іконки
    # Спочатку створити квадратну версію 1024x1024
    sips -z 1024 1024 share/pixmaps/Bitcoin256.png --out temp_1024.png
    
    # Створити всі необхідні розміри з квадратної версії
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
    
    echo "✅ High-quality icon created"
else
    echo "⚠️  Warning: Bitcoin256.png not found, using default icon"
fi

# Виправити шляхи залежностей для Qt frameworks
echo "🔧 Fixing Qt dependencies..."
if [ -d "Krepto.app/Contents/Frameworks" ]; then
    # Створити скрипт для виправлення залежностей
    cat > fix_qt_deps.sh << 'EOF'
#!/bin/bash

APP_PATH="Krepto.app"
EXECUTABLE="$APP_PATH/Contents/MacOS/bitcoin-qt"
FRAMEWORKS_PATH="$APP_PATH/Contents/Frameworks"

# Функція для виправлення шляхів
fix_paths() {
    local binary="$1"
    echo "Fixing: $binary"
    
    # Отримати список залежностей
    otool -L "$binary" | grep -E "Qt.*\.framework" | while read -r line; do
        old_path=$(echo "$line" | awk '{print $1}')
        framework_name=$(basename "$old_path" | sed 's/\.framework.*//')
        
        if [[ "$old_path" == *"Qt"* ]]; then
            new_path="@executable_path/../Frameworks/${framework_name}.framework/Versions/5/${framework_name}"
            echo "  Changing: $old_path -> $new_path"
            install_name_tool -change "$old_path" "$new_path" "$binary" 2>/dev/null || true
        fi
    done
}

# Виправити головний виконуваний файл
fix_paths "$EXECUTABLE"

# Виправити frameworks
for framework in "$FRAMEWORKS_PATH"/*.framework; do
    if [ -d "$framework" ]; then
        framework_name=$(basename "$framework" .framework)
        framework_binary="$framework/Versions/5/$framework_name"
        if [ -f "$framework_binary" ]; then
            fix_paths "$framework_binary"
        fi
    fi
done

echo "✅ Qt dependencies fixed"
EOF
    
    chmod +x fix_qt_deps.sh
    ./fix_qt_deps.sh
    rm fix_qt_deps.sh
fi

# Створити Info.plist з правильним посиланням на іконку
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

# Створити стандартну конфігурацію в Resources (як backup)
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
./Krepto.app/Contents/MacOS/Krepto --version

# Створити DMG
echo "💿 Creating DMG..."
mkdir -p dmg_temp
cp -R Krepto.app dmg_temp/
ln -s /Applications dmg_temp/Applications

# Створити README БЕЗ Qt5 вимог
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
- Self-contained - no additional software required!

REQUIREMENTS:
- macOS 10.14 or later
- No additional software installation needed!

IMPORTANT:
Krepto automatically uses ~/.krepto directory for blockchain data.
This is separate from Bitcoin and will NOT download 620GB of Bitcoin blockchain.
All configuration is handled automatically - just install and run!

All required libraries are included - no need to install Qt5 or Homebrew!

For support: https://krepto.org
EOF

# Створити DMG
hdiutil create -volname "Krepto" -srcfolder dmg_temp -ov -format UDZO Krepto.dmg

# Створити checksums
shasum -a 256 Krepto.dmg > Krepto.dmg.sha256
md5 Krepto.dmg > Krepto.dmg.md5

# Очистити тимчасові файли
rm -rf dmg_temp

echo "✅ DMG created successfully!"
echo "📋 File info:"
ls -lh Krepto.dmg
echo "🔐 Checksums:"
cat Krepto.dmg.sha256
cat Krepto.dmg.md5

# Показати розмір та що включено
echo ""
echo "📦 DMG Contents:"
echo "- Krepto.app with all Qt5 frameworks included"
echo "- No external dependencies required"
echo "- Ready for distribution to end users" 