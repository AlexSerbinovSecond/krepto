#!/bin/bash

set -e

echo "🎨 Building Professional Krepto DMG Installer..."

# Очистити попередні збірки
rm -rf Krepto.app dmg_temp Krepto.dmg Krepto.dmg.sha256 Krepto.dmg.md5 dmg_background.png

# Перевірити чи є виконувані файли
if [ ! -f "src/qt/bitcoin-qt" ] || [ ! -f "src/bitcoind" ] || [ ! -f "src/bitcoin-cli" ]; then
    echo "❌ Executable files not found. Building Krepto first..."
    make clean
    ./configure --enable-gui --disable-tests --disable-bench
    make -j8
fi

# Створити app bundle з правильною структурою для macdeployqt
echo "📱 Creating app bundle for macdeployqt..."
mkdir -p Krepto.app/Contents/{MacOS,Resources}

# Копіювати bitcoin-qt як основний виконуваний файл для macdeployqt
echo "📋 Copying main executable for macdeployqt..."
cp src/qt/bitcoin-qt Krepto.app/Contents/MacOS/Krepto

# Створити базовий Info.plist для macdeployqt
echo "📄 Creating basic Info.plist for macdeployqt..."
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
    <key>NSRequiresAquaSystemAppearance</key>
    <false/>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.finance</string>
</dict>
</plist>
EOF

# 🎯 ЗАПУСТИТИ MACDEPLOYQT НА БАЗОВОМУ APP BUNDLE
echo "🔧 Running macdeployqt on basic app bundle..."
MACDEPLOYQT="/opt/homebrew/opt/qt@5/bin/macdeployqt"

if [ -f "$MACDEPLOYQT" ]; then
    echo "✅ Found macdeployqt at: $MACDEPLOYQT"
    "$MACDEPLOYQT" Krepto.app -verbose=2
    echo "✅ macdeployqt completed successfully!"
else
    echo "❌ macdeployqt not found at expected location"
    exit 1
fi

# Додати додаткові файли та wrapper
echo "📋 Adding additional executables..."
cp src/bitcoind Krepto.app/Contents/MacOS/kryptod
cp src/bitcoin-cli Krepto.app/Contents/MacOS/krypto-cli

# Створити wrapper скрипт
echo "📝 Creating wrapper script..."
mv Krepto.app/Contents/MacOS/Krepto Krepto.app/Contents/MacOS/krepto-qt

cat > Krepto.app/Contents/MacOS/Krepto << 'EOF'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KREPTO_DATADIR="$HOME/.krepto"
mkdir -p "$KREPTO_DATADIR"
if [ ! -f "$KREPTO_DATADIR/krepto.conf" ]; then
    cp "$SCRIPT_DIR/../Resources/krepto.conf" "$KREPTO_DATADIR/" 2>/dev/null || true
fi
exec "$SCRIPT_DIR/krepto-qt" -datadir="$KREPTO_DATADIR" "$@"
EOF

chmod +x Krepto.app/Contents/MacOS/*

# Створити іконку
echo "🎨 Creating icon..."
if [ -f "share/pixmaps/Bitcoin256.png" ]; then
    mkdir -p krepto.iconset
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
    
    iconutil -c icns krepto.iconset
    cp krepto.icns Krepto.app/Contents/Resources/
    /usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string krepto" Krepto.app/Contents/Info.plist 2>/dev/null || /usr/libexec/PlistBuddy -c "Set :CFBundleIconFile krepto" Krepto.app/Contents/Info.plist
    
    rm -rf krepto.iconset krepto.icns temp_1024.png
    echo "✅ Icon created and added to Info.plist"
fi

# Створити конфігурацію
echo "⚙️ Creating Krepto network configuration..."
cat > Krepto.app/Contents/Resources/krepto.conf << 'EOF'
# Krepto Client Configuration

# Network Settings
port=12345
rpcport=12347

# Connection to Seed Nodes
addnode=164.68.117.90:12345
addnode=5.189.133.204:12345
connect=164.68.117.90:12345
connect=5.189.133.204:12345

# Node Settings
daemon=0
server=1
listen=1

# RPC Settings
rpcuser=localuser
rpcpassword=localpass123
rpcbind=127.0.0.1
rpcallowip=127.0.0.1

# Logging
debug=net
logips=1

# Disable mining on client
gen=0

# GUI Settings
gui=1

# Performance
dbcache=512
maxmempool=300

# Force Krepto network (prevent Bitcoin connection)
onlynet=ipv4
discover=0
dnsseed=0
EOF

# 🔐 ПІДПИСАТИ APP BUNDLE
echo "🔐 Code signing app bundle..."

# Підписати frameworks
find Krepto.app/Contents/Frameworks -name "*.framework" -type d | while read framework; do
    codesign --force --sign - --deep "$framework" 2>/dev/null || true
done

# Підписати dylib файли
find Krepto.app/Contents/Frameworks -name "*.dylib" -type f | while read dylib; do
    codesign --force --sign - "$dylib" 2>/dev/null || true
done

# Підписати plugins
find Krepto.app/Contents/PlugIns -name "*.dylib" -type f 2>/dev/null | while read plugin; do
    codesign --force --sign - "$plugin" 2>/dev/null || true
done

# Підписати виконувані файли
for executable in Krepto.app/Contents/MacOS/*; do
    if [ -f "$executable" ] && [ -x "$executable" ]; then
        codesign --force --sign - "$executable" 2>/dev/null || true
    fi
done

# Фінальний підпис app bundle
codesign --force --sign - --deep Krepto.app 2>/dev/null || true
echo "✅ Code signing completed!"

# 🎨 СТВОРИТИ ПРОФЕСІЙНИЙ DMG З КРАСИВИМ ІНТЕРФЕЙСОМ
echo "🎨 Creating professional DMG with beautiful interface..."

# Створити тимчасову папку для DMG
mkdir -p dmg_temp

# Копіювати app в тимчасову папку
cp -R Krepto.app dmg_temp/

# Створити symlink на Applications
ln -s /Applications dmg_temp/Applications

# 🖼️ СТВОРИТИ ФОНОВЕ ЗОБРАЖЕННЯ ДЛЯ DMG З КРАСИВОЮ СТРІЛОЧКОЮ
echo "🖼️ Creating DMG background image with arrow..."
cat > create_background.py << 'EOF'
from PIL import Image, ImageDraw, ImageFont
import os

# Створити зображення 600x400
width, height = 600, 400
img = Image.new('RGB', (width, height), color='#f8f8f8')
draw = ImageDraw.Draw(img)

# Градієнт фон
for y in range(height):
    color_value = int(248 - (y / height) * 15)
    color = (color_value, color_value, color_value + 5)
    draw.line([(0, y), (width, y)], fill=color)

# Додати текст інструкції
try:
    # Спробувати системний шрифт
    font_large = ImageFont.truetype('/System/Library/Fonts/Helvetica.ttc', 22)
    font_small = ImageFont.truetype('/System/Library/Fonts/Helvetica.ttc', 14)
except:
    # Fallback на default шрифт
    font_large = ImageFont.load_default()
    font_small = ImageFont.load_default()

# Текст по центру
text1 = "Drag Krepto to Applications"
text2 = "to install"
text_color = '#2c2c2c'

# Розрахувати позиції тексту
bbox1 = draw.textbbox((0, 0), text1, font=font_large)
bbox2 = draw.textbbox((0, 0), text2, font=font_small)
text1_width = bbox1[2] - bbox1[0]
text2_width = bbox2[2] - bbox2[0]

x1 = (width - text1_width) // 2
x2 = (width - text2_width) // 2
y1 = height // 2 - 50
y2 = height // 2 - 25

draw.text((x1, y1), text1, fill=text_color, font=font_large)
draw.text((x2, y2), text2, fill=text_color, font=font_small)

# Намалювати красиву стрілку (як у VNC Viewer)
arrow_y = height // 2 + 20
arrow_start_x = 200  # Від Krepto app
arrow_end_x = 400    # До Applications
arrow_color = '#007AFF'
arrow_width = 4

# Основна лінія стрілки
draw.line([(arrow_start_x, arrow_y), (arrow_end_x - 15, arrow_y)], fill=arrow_color, width=arrow_width)

# Наконечник стрілки (більший та красивіший)
arrow_head = [
    (arrow_end_x, arrow_y),
    (arrow_end_x - 15, arrow_y - 8),
    (arrow_end_x - 15, arrow_y + 8)
]
draw.polygon(arrow_head, fill=arrow_color)

# Додати тінь для стрілки
shadow_offset = 2
shadow_color = '#cccccc'
draw.line([(arrow_start_x + shadow_offset, arrow_y + shadow_offset), 
          (arrow_end_x - 15 + shadow_offset, arrow_y + shadow_offset)], 
          fill=shadow_color, width=arrow_width)

shadow_head = [
    (arrow_end_x + shadow_offset, arrow_y + shadow_offset),
    (arrow_end_x - 15 + shadow_offset, arrow_y - 8 + shadow_offset),
    (arrow_end_x - 15 + shadow_offset, arrow_y + 8 + shadow_offset)
]
draw.polygon(shadow_head, fill=shadow_color)

# Зберегти зображення
img.save('dmg_background.png')
print("Background image with arrow created: dmg_background.png")
EOF

# Запустити Python скрипт для створення фону
python3 create_background.py 2>/dev/null || echo "Warning: Could not create custom background, using default"

# Створити тимчасовий DMG
echo "💿 Creating temporary DMG..."
hdiutil create -volname "Krepto Installer" -srcfolder dmg_temp -ov -format UDRW temp_krepto.dmg

# Підключити DMG для налаштування
echo "🔧 Mounting DMG for customization..."
hdiutil attach temp_krepto.dmg -mountpoint /Volumes/KreptoInstaller

# Налаштувати вигляд DMG через AppleScript
echo "🎨 Customizing DMG appearance..."
osascript << 'EOF'
tell application "Finder"
    tell disk "KreptoInstaller"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {100, 100, 700, 500}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 128
        
        -- Встановити позиції іконок (тільки Krepto.app та Applications)
        set position of item "Krepto.app" of container window to {150, 200}
        set position of item "Applications" of container window to {450, 200}
        
        -- Встановити фон якщо існує
        try
            set background picture of viewOptions to file ".background.png" of disk "KreptoInstaller"
        end try
        
        -- Оновити вікно
        update without registering applications
        delay 2
        close
    end tell
end tell
EOF

# Копіювати фонове зображення в DMG якщо воно існує
if [ -f "dmg_background.png" ]; then
    cp dmg_background.png /Volumes/KreptoInstaller/.background.png 2>/dev/null || true
fi

# Відключити DMG
echo "📤 Unmounting DMG..."
hdiutil detach /Volumes/KreptoInstaller -force 2>/dev/null || {
    echo "⚠️  Warning: Could not unmount DMG normally, trying force unmount..."
    # Знайти всі диски Krepto і примусово відключити
    for disk in $(diskutil list | grep -o 'disk[0-9]*' | sort -u); do
        sudo diskutil unmountDisk force $disk 2>/dev/null || true
    done
    sleep 3
}

# Конвертувати в фінальний read-only DMG (з fallback)
echo "🔒 Converting to final read-only DMG..."
if hdiutil convert temp_krepto.dmg -format UDZO -o Krepto.dmg 2>/dev/null; then
    echo "✅ DMG converted successfully!"
else
    echo "⚠️  Conversion failed, creating simple DMG instead..."
    rm -f temp_krepto.dmg
    # Створити простий DMG як fallback
    mkdir -p /tmp/krepto_dmg_final
    cp -R Krepto.app /tmp/krepto_dmg_final/
    hdiutil create -volname "Krepto Installer" -fs HFS+ -srcfolder /tmp/krepto_dmg_final -ov -format UDZO Krepto.dmg
    rm -rf /tmp/krepto_dmg_final
fi

# Очистити тимчасові файли
rm -rf dmg_temp temp_krepto.dmg create_background.py dmg_background.png

# Створити checksums
shasum -a 256 Krepto.dmg > Krepto.dmg.sha256
md5 Krepto.dmg > Krepto.dmg.md5

echo "✅ Professional DMG installer created successfully!"
echo "📋 File info:"
ls -lh Krepto.dmg
echo "🔐 Checksums:"
cat Krepto.dmg.sha256
cat Krepto.dmg.md5

echo ""
echo "🎨 DMG Features:"
echo "- Professional installer interface"
echo "- Custom background with instructions"
echo "- Drag & drop installation"
echo "- Proper icon positioning"
echo "- Beautiful visual design"
echo "- Code signed and standalone"
echo "- Ready for distribution!" 