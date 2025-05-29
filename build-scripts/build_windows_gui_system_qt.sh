#!/bin/bash

set -e

echo "🪟 Building Krepto Windows GUI with System Qt5..."

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

# Перевірити Qt5
QT5_PATH="/opt/homebrew/opt/qt@5"
if [ ! -d "$QT5_PATH" ]; then
    QT5_PATH="/usr/local/opt/qt@5"
fi

if [ ! -d "$QT5_PATH" ]; then
    echo "❌ Qt5 not found. Installing..."
    brew install qt@5
    QT5_PATH="/opt/homebrew/opt/qt@5"
fi

echo "✅ Qt5 found at: $QT5_PATH"

# Очистити попередню збірку
echo "🧹 Cleaning previous build..."
make clean 2>/dev/null || true

# Спробувати збудувати мінімальні залежності без Qt5
echo "📦 Building minimal dependencies (without Qt5)..."
cd depends

# Очистити depends
make clean HOST=x86_64-w64-mingw32 2>/dev/null || true

# Збудувати тільки необхідні залежності (без Qt5)
echo "🔧 Building essential dependencies..."
make -j4 HOST=x86_64-w64-mingw32 boost libevent zeromq

cd ..

# Налаштувати збірку з системним Qt5
echo "⚙️ Configuring with system Qt5..."

# Встановити змінні для Qt5
export PKG_CONFIG_PATH="$QT5_PATH/lib/pkgconfig:$PKG_CONFIG_PATH"
export Qt5_DIR="$QT5_PATH/lib/cmake/Qt5"
export QT_SELECT=qt5

# Запустити autogen
./autogen.sh

# Конфігурувати з системним Qt5
CONFIG_SITE=$PWD/depends/x86_64-w64-mingw32/share/config.site ./configure \
    --prefix=/ \
    --host=x86_64-w64-mingw32 \
    --disable-tests \
    --disable-bench \
    --with-gui=qt5 \
    --with-qt-bindir="$QT5_PATH/bin" \
    --with-qt-libdir="$QT5_PATH/lib" \
    --with-qt-incdir="$QT5_PATH/include" \
    PKG_CONFIG_PATH="$QT5_PATH/lib/pkgconfig"

echo "🔨 Building Krepto with GUI..."
make -j8

echo "✅ Build completed! Checking for GUI executable..."
if [ -f "src/qt/bitcoin-qt.exe" ]; then
    echo "🎉 SUCCESS: GUI executable created!"
    ls -lh src/qt/bitcoin-qt.exe
else
    echo "❌ GUI executable not found"
    echo "Available executables:"
    ls -la src/*.exe 2>/dev/null || echo "No executables found"
fi

echo "📋 Build summary:"
echo "- Daemon: $(ls -lh src/bitcoind.exe 2>/dev/null || echo 'Not found')"
echo "- CLI: $(ls -lh src/bitcoin-cli.exe 2>/dev/null || echo 'Not found')"
echo "- GUI: $(ls -lh src/qt/bitcoin-qt.exe 2>/dev/null || echo 'Not found')" 