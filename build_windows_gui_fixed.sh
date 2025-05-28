#!/bin/bash

set -e

echo "🪟 Building Krepto Windows GUI Version (Fixed)..."

# Перевірити наявність mingw
if ! command -v x86_64-w64-mingw32-g++ &> /dev/null; then
    echo "❌ mingw-w64 not found. Installing..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install mingw-w64
    else
        echo "Please install mingw-w64 manually"
        exit 1
    fi
fi

echo "✅ mingw-w64 found: $(x86_64-w64-mingw32-g++ --version | head -1)"

# Очистити попередню збірку
echo "🧹 Cleaning previous build..."
make clean 2>/dev/null || true

# Спробувати використати існуючі залежності без Qt5
echo "📦 Checking existing dependencies..."
cd depends

# Очистити тільки Qt5, залишити інші залежності
echo "🧹 Cleaning only Qt5..."
rm -rf built/x86_64-w64-mingw32/qt/ 2>/dev/null || true
rm -rf work/x86_64-w64-mingw32/qt/ 2>/dev/null || true

# Збудувати базові залежності без Qt5
echo "📦 Building base dependencies without Qt5..."
make -j4 HOST=x86_64-w64-mingw32 NO_QT=1 || {
    echo "❌ Dependencies build failed, trying alternative approach..."
    
    # Альтернативний підхід - збудувати тільки необхідні пакети
    echo "📦 Building essential packages only..."
    make -j4 HOST=x86_64-w64-mingw32 boost libevent zeromq || {
        echo "❌ Essential packages build failed"
        exit 1
    }
}

cd ..

echo "⚙️ Configuring for Windows build..."
./autogen.sh

# Конфігутувати без Qt5 спочатку
CONFIG_SITE=$PWD/depends/x86_64-w64-mingw32/share/config.site ./configure \
    --prefix=/ \
    --host=x86_64-w64-mingw32 \
    --disable-tests \
    --disable-bench \
    --with-gui=no \
    --enable-wallet \
    --with-miniupnpc \
    --enable-upnp-default

echo "🔨 Building CLI version first..."
make -j8

# Зберегти CLI файли
echo "💾 Backing up CLI files..."
mkdir -p backup_cli
cp src/bitcoind.exe backup_cli/ 2>/dev/null || true
cp src/bitcoin-cli.exe backup_cli/ 2>/dev/null || true
cp src/bitcoin-tx.exe backup_cli/ 2>/dev/null || true
cp src/bitcoin-util.exe backup_cli/ 2>/dev/null || true
cp src/bitcoin-wallet.exe backup_cli/ 2>/dev/null || true

# Тепер спробуємо збудувати Qt5 з виправленнями
echo "🎨 Attempting to build Qt5 with fixes..."
cd depends

# Створити патч для Qt5 Windows збірки
echo "🔧 Creating Qt5 Windows patch..."
cat > qt_windows_fix.patch << 'EOF'
--- a/packages/qt.mk
+++ b/packages/qt.mk
@@ -85,6 +85,7 @@ $(package)_config_opts_mingw32 += "QMAKE_LFLAGS = '$($(package)_ldflags)'"
 $(package)_config_opts_mingw32 += "QMAKE_LIB = '$($(package)_ar) rc'"
 $(package)_config_opts_mingw32 += -device-option CROSS_COMPILE="$(host)-"
 $(package)_config_opts_mingw32 += -pch
+$(package)_config_opts_mingw32 += -no-feature-macdeployqt
 ifneq ($(LTO),)
 $(package)_config_opts_mingw32 += -ltcg
 endif
EOF

# Застосувати патч
patch -p1 < qt_windows_fix.patch 2>/dev/null || echo "Patch already applied or not needed"

# Спробувати збудувати Qt5 з виправленнями
echo "🎨 Building Qt5 for Windows..."
make -j2 HOST=x86_64-w64-mingw32 qt 2>&1 | tee qt_build.log || {
    echo "⚠️ Qt5 build failed, checking for partial success..."
    
    # Перевірити, чи є частково збудовані Qt5 файли
    if [ -d "built/x86_64-w64-mingw32/qt" ]; then
        echo "✅ Found partial Qt5 build, continuing..."
    else
        echo "❌ Qt5 build completely failed, falling back to CLI only"
        cd ..
        
        # Створити пакет з CLI версією
        echo "📦 Creating CLI-only package..."
        ./create_windows_package.sh
        
        echo "✅ CLI package created successfully!"
        echo "❌ GUI version could not be built due to Qt5 issues"
        exit 0
    fi
}

cd ..

# Якщо Qt5 збудувався, спробувати конфігурувати з GUI
if [ -d "depends/built/x86_64-w64-mingw32/qt" ]; then
    echo "🎨 Qt5 found, configuring with GUI..."
    
    make clean
    
    CONFIG_SITE=$PWD/depends/x86_64-w64-mingw32/share/config.site ./configure \
        --prefix=/ \
        --host=x86_64-w64-mingw32 \
        --disable-tests \
        --disable-bench \
        --with-gui=qt5 \
        --enable-wallet \
        --with-miniupnpc \
        --enable-upnp-default
    
    echo "🔨 Building GUI version..."
    make -j8 2>&1 | tee gui_build.log || {
        echo "❌ GUI build failed, restoring CLI files..."
        
        # Відновити CLI файли
        cp backup_cli/* src/ 2>/dev/null || true
        
        echo "📦 Creating CLI package..."
        ./create_windows_package.sh
        
        echo "✅ CLI package created!"
        echo "❌ GUI version failed to build"
        exit 0
    }
    
    # Перевірити, чи створився bitcoin-qt.exe
    if [ -f "src/qt/bitcoin-qt.exe" ]; then
        echo "🎉 SUCCESS! GUI version built successfully!"
        
        # Створити GUI пакет
        echo "📦 Creating GUI package..."
        PACKAGE_DIR="Krepto-Windows-GUI-Complete"
        rm -rf "$PACKAGE_DIR"
        mkdir -p "$PACKAGE_DIR"
        
        # Копіювати GUI та CLI файли
        cp src/qt/bitcoin-qt.exe "$PACKAGE_DIR/krepto-qt.exe"
        cp src/bitcoind.exe "$PACKAGE_DIR/kryptod.exe"
        cp src/bitcoin-cli.exe "$PACKAGE_DIR/krepto-cli.exe"
        cp src/bitcoin-tx.exe "$PACKAGE_DIR/krepto-tx.exe"
        cp src/bitcoin-util.exe "$PACKAGE_DIR/krepto-util.exe"
        cp src/bitcoin-wallet.exe "$PACKAGE_DIR/krepto-wallet.exe"
        
        # Додати Qt5 DLL файли
        echo "📚 Adding Qt5 dependencies..."
        QT_DIR="depends/built/x86_64-w64-mingw32/qt"
        if [ -d "$QT_DIR" ]; then
            mkdir -p "$PACKAGE_DIR/platforms"
            
            # Основні Qt5 DLL
            find "$QT_DIR" -name "*.dll" -exec cp {} "$PACKAGE_DIR/" \; 2>/dev/null || true
            
            # Qt5 плагіни
            find "$QT_DIR" -path "*/platforms/*.dll" -exec cp {} "$PACKAGE_DIR/platforms/" \; 2>/dev/null || true
        fi
        
        # Додати mingw DLL
        echo "📚 Adding mingw dependencies..."
        MINGW_PATH=$(dirname $(which x86_64-w64-mingw32-g++))
        cp "$MINGW_PATH/../x86_64-w64-mingw32/lib/libwinpthread-1.dll" "$PACKAGE_DIR/" 2>/dev/null || true
        cp "$MINGW_PATH/../lib/gcc/x86_64-w64-mingw32/*/libgcc_s_seh-1.dll" "$PACKAGE_DIR/" 2>/dev/null || true
        cp "$MINGW_PATH/../lib/gcc/x86_64-w64-mingw32/*/libstdc++-6.dll" "$PACKAGE_DIR/" 2>/dev/null || true
        
        # Створити конфігурацію
        cat > "$PACKAGE_DIR/bitcoin.conf" << 'EOF'
# Krepto Configuration
rpcuser=kreptouser
rpcpassword=kreptopass123
rpcport=12347
port=12345
server=1
daemon=1
txindex=1

# Seed nodes
addnode=164.68.117.90:12345
addnode=5.189.133.204:12345
connect=164.68.117.90:12345
connect=5.189.133.204:12345
EOF
        
        # Створити batch файли
        cat > "$PACKAGE_DIR/start-krepto-gui.bat" << 'EOF'
@echo off
echo Starting Krepto GUI...
krepto-qt.exe
pause
EOF
        
        cat > "$PACKAGE_DIR/README.txt" << 'EOF'
Krepto Windows GUI Version
==========================

Files included:
- krepto-qt.exe     - Main GUI application
- kryptod.exe       - Daemon/server
- krepto-cli.exe    - Command line interface
- krepto-tx.exe     - Transaction utility
- krepto-util.exe   - General utility
- krepto-wallet.exe - Wallet management tool

Quick Start:
1. Double-click start-krepto-gui.bat to launch the GUI
2. The application will automatically connect to the Krepto network
3. Create a new wallet or import an existing one

Network Information:
- Network: Krepto Mainnet
- Port: 12345
- RPC Port: 12347
- Seed Nodes: 164.68.117.90:12345, 5.189.133.204:12345

For support, visit: https://krepto.org
EOF
        
        # Створити ZIP архів
        echo "📦 Creating ZIP package..."
        zip -r "Krepto-Windows-GUI-Complete.zip" "$PACKAGE_DIR/"
        
        # Показати результат
        echo ""
        echo "🎉 SUCCESS! Krepto Windows GUI Version Created!"
        echo "📁 Package: Krepto-Windows-GUI-Complete.zip"
        echo "📊 Size: $(du -h Krepto-Windows-GUI-Complete.zip | cut -f1)"
        echo ""
        echo "✅ Included files:"
        echo "  - krepto-qt.exe (GUI application)"
        echo "  - All CLI tools"
        echo "  - Qt5 dependencies"
        echo "  - Configuration files"
        echo "  - User documentation"
        
    else
        echo "❌ bitcoin-qt.exe not found, GUI build failed"
        
        # Відновити CLI файли та створити CLI пакет
        cp backup_cli/* src/ 2>/dev/null || true
        ./create_windows_package.sh
        
        echo "✅ CLI package created as fallback"
    fi
else
    echo "❌ Qt5 not available, creating CLI package only..."
    
    # Відновити CLI файли
    cp backup_cli/* src/ 2>/dev/null || true
    ./create_windows_package.sh
    
    echo "✅ CLI package created!"
fi

# Очистити тимчасові файли
rm -rf backup_cli 2>/dev/null || true

echo "🏁 Build process completed!" 