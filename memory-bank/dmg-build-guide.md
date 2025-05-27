# Krepto DMG Build Guide - macOS Інсталятор

## 🎯 МЕТА
Створити готовий до розповсюдження DMG інсталятор для macOS, щоб користувачі могли:
1. Скачати один файл `Krepto.dmg`
2. Встановити Krepto простим перетягуванням
3. Одразу почати майніти через GUI

## 📦 ЩО ВКЛЮЧАЄ DMG

### Основні Компоненти
1. **Krepto.app** - GUI додаток з майнінгом
2. **kryptod** - daemon (вбудований в .app)
3. **krypto-cli** - CLI інструменти (вбудований в .app)
4. **Автоматичний запуск** - daemon стартує з GUI
5. **Готова конфігурація** - працює "з коробки"

### Користувацький Досвід
```
1. Скачати Krepto.dmg
2. Відкрити DMG
3. Перетягнути Krepto.app в Applications
4. Запустити Krepto
5. Натиснути "Start Mining" - готово!
```

## 🛠️ КРОК 1: ПІДГОТОВКА ЗБІРКИ

### 1.1 Перевірка Поточної Збірки
```bash
cd /Users/serbinov/Desktop/projects/upwork/krepto

# Перевірити чи є GUI
ls -la src/qt/bitcoin-qt

# Перевірити daemon
ls -la src/bitcoind

# Перевірити CLI
ls -la src/bitcoin-cli
```

### 1.2 Збірка з Оптимізацією для Релізу
```bash
# Очистити попередню збірку
make clean

# Налаштувати для релізу
./configure \
    --enable-gui \
    --disable-tests \
    --disable-bench \
    --with-gui=qt5 \
    --enable-reduce-exports \
    --disable-debug

# Збірка оптимізованої версії
make -j8
```

### 1.3 Перевірка Залежностей
```bash
# Перевірити Qt залежності
otool -L src/qt/bitcoin-qt

# Перевірити daemon залежності  
otool -L src/bitcoind

# Встановити додаткові інструменти якщо потрібно
brew install create-dmg
```

## 📱 КРОК 2: СТВОРЕННЯ KREPTO.APP BUNDLE

### 2.1 Структура App Bundle
```
Krepto.app/
├── Contents/
│   ├── Info.plist
│   ├── MacOS/
│   │   ├── Krepto (головний виконуваний файл)
│   │   ├── kryptod (daemon)
│   │   └── krypto-cli (CLI)
│   ├── Resources/
│   │   ├── krepto.icns (іконка)
│   │   ├── bitcoin.conf (конфігурація)
│   │   └── qt.conf (Qt конфігурація)
│   └── Frameworks/ (Qt бібліотеки)
```

### 2.2 Створення Директорій
```bash
# Створити структуру app bundle
mkdir -p Krepto.app/Contents/{MacOS,Resources,Frameworks}

# Скопіювати основні файли
cp src/qt/bitcoin-qt Krepto.app/Contents/MacOS/Krepto
cp src/bitcoind Krepto.app/Contents/MacOS/kryptod
cp src/bitcoin-cli Krepto.app/Contents/MacOS/krypto-cli

# Зробити виконуваними
chmod +x Krepto.app/Contents/MacOS/*
```

### 2.3 Створення Info.plist
```bash
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
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeExtensions</key>
            <array>
                <string>krepto</string>
            </array>
            <key>CFBundleTypeName</key>
            <string>Krepto Wallet</string>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
        </dict>
    </array>
</dict>
</plist>
EOF
```

### 2.4 Створення Іконки
```bash
# Якщо є PNG іконка, конвертувати в ICNS
# Потрібна іконка 1024x1024 PNG
if [ -f "share/pixmaps/bitcoin.png" ]; then
    # Створити icns з PNG
    mkdir -p krepto.iconset
    
    # Створити різні розміри
    sips -z 16 16 share/pixmaps/bitcoin.png --out krepto.iconset/icon_16x16.png
    sips -z 32 32 share/pixmaps/bitcoin.png --out krepto.iconset/icon_16x16@2x.png
    sips -z 32 32 share/pixmaps/bitcoin.png --out krepto.iconset/icon_32x32.png
    sips -z 64 64 share/pixmaps/bitcoin.png --out krepto.iconset/icon_32x32@2x.png
    sips -z 128 128 share/pixmaps/bitcoin.png --out krepto.iconset/icon_128x128.png
    sips -z 256 256 share/pixmaps/bitcoin.png --out krepto.iconset/icon_128x128@2x.png
    sips -z 256 256 share/pixmaps/bitcoin.png --out krepto.iconset/icon_256x256.png
    sips -z 512 512 share/pixmaps/bitcoin.png --out krepto.iconset/icon_256x256@2x.png
    sips -z 512 512 share/pixmaps/bitcoin.png --out krepto.iconset/icon_512x512.png
    sips -z 1024 1024 share/pixmaps/bitcoin.png --out krepto.iconset/icon_512x512@2x.png
    
    # Створити ICNS
    iconutil -c icns krepto.iconset
    cp krepto.icns Krepto.app/Contents/Resources/
    
    # Очистити тимчасові файли
    rm -rf krepto.iconset krepto.icns
fi
```

### 2.5 Конфігурація для "З Коробки"
```bash
# Створити стандартну конфігурацію
cat > Krepto.app/Contents/Resources/bitcoin.conf << 'EOF'
# Krepto Default Configuration

# Network
port=12345
rpcport=12347

# RPC (для GUI)
server=1
rpcuser=kreptouser
rpcpassword=kreptopass123

# GUI Settings
gui=1
splash=1

# Mining (готово до використання)
gen=0

# Network
listen=1
discover=1
maxconnections=125

# Performance
dbcache=512
maxmempool=300

# Logging
debug=0
EOF
```

## 🔗 КРОК 3: ВКЛЮЧЕННЯ QT ЗАЛЕЖНОСТЕЙ

### 3.1 Копіювання Qt Frameworks
```bash
# Знайти Qt frameworks
QT_PATH=$(brew --prefix qt@5)

# Скопіювати необхідні Qt frameworks
cp -R "$QT_PATH/lib/QtCore.framework" Krepto.app/Contents/Frameworks/
cp -R "$QT_PATH/lib/QtGui.framework" Krepto.app/Contents/Frameworks/
cp -R "$QT_PATH/lib/QtWidgets.framework" Krepto.app/Contents/Frameworks/
cp -R "$QT_PATH/lib/QtNetwork.framework" Krepto.app/Contents/Frameworks/

# Створити qt.conf для правильних шляхів
cat > Krepto.app/Contents/Resources/qt.conf << 'EOF'
[Paths]
Frameworks = ../Frameworks
EOF
```

### 3.2 Виправлення Шляхів Залежностей
```bash
# Скрипт для виправлення шляхів
cat > fix_dependencies.sh << 'EOF'
#!/bin/bash

APP_PATH="Krepto.app"
EXECUTABLE="$APP_PATH/Contents/MacOS/Krepto"
FRAMEWORKS_PATH="$APP_PATH/Contents/Frameworks"

# Функція для виправлення шляхів
fix_paths() {
    local binary="$1"
    
    # Отримати список залежностей
    otool -L "$binary" | grep -E "(Qt|@rpath)" | while read -r line; do
        old_path=$(echo "$line" | awk '{print $1}')
        framework_name=$(basename "$old_path" | sed 's/\.framework.*//')
        
        if [[ "$old_path" == *"Qt"* ]]; then
            new_path="@executable_path/../Frameworks/${framework_name}.framework/Versions/5/${framework_name}"
            install_name_tool -change "$old_path" "$new_path" "$binary"
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

echo "Dependencies fixed!"
EOF

chmod +x fix_dependencies.sh
./fix_dependencies.sh
```

## 🎨 КРОК 4: СТВОРЕННЯ DMG ОБРАЗУ

### 4.1 Підготовка DMG Контенту
```bash
# Створити тимчасову директорію для DMG
mkdir -p dmg_temp

# Скопіювати app bundle
cp -R Krepto.app dmg_temp/

# Створити симлінк на Applications
ln -s /Applications dmg_temp/Applications

# Створити README файл
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

For support: https://krepto.org
EOF
```

### 4.2 Створення DMG з create-dmg
```bash
# Створити DMG з красивим дизайном
create-dmg \
    --volname "Krepto Installer" \
    --volicon "Krepto.app/Contents/Resources/krepto.icns" \
    --window-pos 200 120 \
    --window-size 800 600 \
    --icon-size 100 \
    --icon "Krepto.app" 200 190 \
    --hide-extension "Krepto.app" \
    --app-drop-link 600 190 \
    --background "dmg_background.png" \
    "Krepto.dmg" \
    "dmg_temp/"
```

### 4.3 Альтернативний Метод (hdiutil)
```bash
# Якщо create-dmg не працює, використати hdiutil
if [ ! -f "Krepto.dmg" ]; then
    # Створити DMG образ
    hdiutil create -volname "Krepto" -srcfolder dmg_temp -ov -format UDZO Krepto.dmg
    
    echo "DMG created with hdiutil"
fi
```

## 🧪 КРОК 5: ТЕСТУВАННЯ DMG

### 5.1 Монтування та Перевірка
```bash
# Змонтувати DMG
hdiutil attach Krepto.dmg

# Перевірити вміст
ls -la /Volumes/Krepto*/

# Тестова установка
cp -R "/Volumes/Krepto/Krepto.app" /tmp/test_krepto.app

# Перевірити чи запускається
/tmp/test_krepto.app/Contents/MacOS/Krepto --version

# Розмонтувати
hdiutil detach /Volumes/Krepto*

# Очистити тест
rm -rf /tmp/test_krepto.app
```

### 5.2 Перевірка Розміру та Оптимізація
```bash
# Перевірити розмір DMG
ls -lh Krepto.dmg

# Якщо занадто великий, оптимізувати
if [ $(stat -f%z Krepto.dmg) -gt 500000000 ]; then
    echo "DMG is large (>500MB), optimizing..."
    
    # Стиснути DMG
    hdiutil convert Krepto.dmg -format UDZO -o Krepto_compressed.dmg
    mv Krepto_compressed.dmg Krepto.dmg
fi
```

## 🚀 КРОК 6: АВТОМАТИЗАЦІЯ ЗБІРКИ

### 6.1 Створення Build Скрипта
```bash
cat > build_dmg.sh << 'EOF'
#!/bin/bash

set -e

echo "🚀 Building Krepto DMG..."

# Очистити попередні збірки
rm -rf Krepto.app dmg_temp Krepto.dmg

# Збірка проєкту
echo "📦 Building Krepto..."
make clean
./configure --enable-gui --disable-tests --disable-bench
make -j8

# Створити app bundle
echo "📱 Creating app bundle..."
mkdir -p Krepto.app/Contents/{MacOS,Resources,Frameworks}

# Копіювати файли
cp src/qt/bitcoin-qt Krepto.app/Contents/MacOS/Krepto
cp src/bitcoind Krepto.app/Contents/MacOS/kryptod
cp src/bitcoin-cli Krepto.app/Contents/MacOS/krypto-cli
chmod +x Krepto.app/Contents/MacOS/*

# Створити Info.plist та конфігурацію
# (код з попередніх кроків)

# Включити Qt залежності
echo "🔗 Including Qt dependencies..."
# (код з кроку 3)

# Створити DMG
echo "💿 Creating DMG..."
mkdir -p dmg_temp
cp -R Krepto.app dmg_temp/
ln -s /Applications dmg_temp/Applications

# Створити DMG
hdiutil create -volname "Krepto" -srcfolder dmg_temp -ov -format UDZO Krepto.dmg

# Очистити тимчасові файли
rm -rf dmg_temp Krepto.app

echo "✅ DMG created: Krepto.dmg"
ls -lh Krepto.dmg
EOF

chmod +x build_dmg.sh
```

### 6.2 Запуск Автоматичної Збірки
```bash
# Запустити збірку DMG
./build_dmg.sh
```

## 📋 КРОК 7: ФІНАЛЬНА ПЕРЕВІРКА

### 7.1 Тестування Повного Циклу
```bash
echo "🧪 Testing complete installation cycle..."

# 1. Монтувати DMG
hdiutil attach Krepto.dmg

# 2. Встановити в Applications
sudo cp -R "/Volumes/Krepto/Krepto.app" /Applications/

# 3. Запустити Krepto
open /Applications/Krepto.app

# 4. Перевірити чи daemon запустився
sleep 10
ps aux | grep kryptod

# 5. Перевірити RPC з'єднання
/Applications/Krepto.app/Contents/MacOS/krypto-cli getblockchaininfo

echo "✅ Installation test completed!"
```

### 7.2 Створення Checksums
```bash
# Створити checksums для верифікації
shasum -a 256 Krepto.dmg > Krepto.dmg.sha256
md5 Krepto.dmg > Krepto.dmg.md5

echo "📋 Checksums created:"
cat Krepto.dmg.sha256
cat Krepto.dmg.md5
```

## 📊 ОЧІКУВАНИЙ РЕЗУЛЬТАТ

### Що Отримаємо
1. **Krepto.dmg** (~200-500MB) - готовий інсталятор
2. **Простота установки** - перетягнути в Applications
3. **Все включено** - GUI, daemon, CLI, конфігурація
4. **Працює з коробки** - одразу готовий до майнінгу

### Користувацький Досвід
```
Користувач:
1. Скачує Krepto.dmg
2. Відкриває DMG
3. Перетягує Krepto.app в Applications
4. Запускає Krepto
5. Натискає "Start Mining"
6. Майнінг працює!
```

### Технічні Деталі
- **Розмір**: 200-500MB (залежно від Qt)
- **Сумісність**: macOS 10.14+
- **Архітектура**: x86_64 (Intel/Apple Silicon через Rosetta)
- **Підпис**: Без підпису (для тестування)

## 🎯 НАСТУПНІ КРОКИ

1. **Запустити збірку** - виконати build_dmg.sh
2. **Протестувати DMG** - встановити та перевірити
3. **Оптимізувати розмір** - якщо потрібно
4. **Створити checksums** - для безпеки
5. **Підготувати до розповсюдження** - завантажити на сервер

**DMG ГОТОВИЙ ДО ЗБІРКИ!** 🚀 