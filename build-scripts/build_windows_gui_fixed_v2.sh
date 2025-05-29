#!/bin/bash

# Krepto Windows GUI Build Script v2 - Fixed with DeepResearch recommendations
# Based on comprehensive analysis of Qt5 cross-compilation issues

set -e

echo "🚀 Krepto Windows GUI Build v2 - DeepResearch Fixed"
echo "=================================================="

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
DEPENDS_DIR="$BUILD_DIR/depends"

echo -e "${BLUE}Configuration:${NC}"
echo "  HOST: $HOST"
echo "  CPU cores: $NCPU"
echo "  Build directory: $BUILD_DIR"
echo "  Depends directory: $DEPENDS_DIR"

# Step 1: Verify MinGW toolchain
echo -e "\n${YELLOW}Step 1: Verifying MinGW toolchain...${NC}"
if ! command -v ${HOST}-g++ &> /dev/null; then
    echo -e "${RED}Error: MinGW toolchain not found. Installing...${NC}"
    brew install mingw-w64
fi

# Check if it's POSIX threads variant (recommended by DeepResearch)
echo "Checking MinGW thread model..."
THREAD_MODEL=$(${HOST}-g++ -v 2>&1 | grep "Thread model" | awk '{print $3}')
echo "Thread model: $THREAD_MODEL"
if [ "$THREAD_MODEL" != "posix" ]; then
    echo -e "${YELLOW}Warning: Thread model is not 'posix'. This might cause issues.${NC}"
fi

# Step 2: Clean previous builds
echo -e "\n${YELLOW}Step 2: Cleaning previous builds...${NC}"
make distclean 2>/dev/null || true
cd depends
make clean 2>/dev/null || true
rm -rf work built ${HOST} 2>/dev/null || true
cd ..

# Step 3: Fix depends/packages/qt.mk according to DeepResearch recommendations
echo -e "\n${YELLOW}Step 3: Applying DeepResearch fixes to qt.mk...${NC}"

# Backup original qt.mk
cp depends/packages/qt.mk depends/packages/qt.mk.backup

# Create the fixed qt.mk
cat > depends/packages/qt.mk << 'EOF'
package=qt
$(package)_version=5.15.5
$(package)_download_path=https://download.qt.io/official_releases/qt/5.15/$($(package)_version)/submodules
$(package)_suffix=everywhere-opensource-src-$($(package)_version).tar.xz
$(package)_file_name=qtbase-$($(package)_suffix)
$(package)_sha256_hash=0c42c799aa5cdd1c4e4c5a4b8c4c8e8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c
$(package)_dependencies=
$(package)_linux_dependencies=freetype fontconfig libxcb libxkbcommon
$(package)_qt_libs=corelib network widgets gui plugins testlib
$(package)_patches=qt.pro qtbase.pro

define $(package)_set_vars
$(package)_config_opts = -release -opensource -confirm-license
$(package)_config_opts += -static
$(package)_config_opts += -no-shared
$(package)_config_opts += -no-opengl
$(package)_config_opts += -no-cups
$(package)_config_opts += -no-iconv
$(package)_config_opts += -no-icu
$(package)_config_opts += -no-gif
$(package)_config_opts += -no-freetype
$(package)_config_opts += -no-dbus
$(package)_config_opts += -no-openssl
$(package)_config_opts += -no-feature-concurrent
$(package)_config_opts += -no-feature-xml
$(package)_config_opts += -no-feature-sql
$(package)_config_opts += -no-feature-testlib
$(package)_config_opts += -make libs
$(package)_config_opts += -nomake examples
$(package)_config_opts += -nomake tests
$(package)_config_opts += -nomake tools
$(package)_config_opts += -qt-zlib
$(package)_config_opts += -qt-libpng
$(package)_config_opts += -qt-libjpeg
$(package)_config_opts += -prefix $(host_prefix)

# CRITICAL FIX: MinGW-specific configuration (DeepResearch recommendations)
ifneq ($(findstring x86_64-w64-mingw32,$(HOST)),)
  # Prevent host CFLAGS/CXXFLAGS/LDFLAGS from being used
  NO_HOST_CFLAGS = 1
  NO_HOST_CXXFLAGS = 1
  NO_HOST_LDFLAGS = 1

  # Explicitly set MinGW tools for Qt's configure script environment
  $(package)_config_env += \
    CC="$(HOST)-gcc" \
    CXX="$(HOST)-g++" \
    AR="$(HOST)-ar" \
    RANLIB="$(HOST)-ranlib" \
    STRIP="$(HOST)-strip" \
    PKG_CONFIG_SYSROOT_DIR="/" \
    PKG_CONFIG_PATH="" \
    PKG_CONFIG_LIBDIR="$(HOST_PKG_CONFIG_LIBDIR)" \
    QMAKESPEC=win32-g++

  # CRITICAL: Sanitize TARGET_CFLAGS and TARGET_CXXFLAGS to remove macOS flags
  _SANITIZED_TARGET_CFLAGS := $(filter-out -fconstant-cfstrings -stdlib=libc++ -mmacosx-version-min=%,$(TARGET_CFLAGS))
  _SANITIZED_TARGET_CXXFLAGS := $(filter-out -fconstant-cfstrings -stdlib=libc++ -mmacosx-version-min=%,$(TARGET_CXXFLAGS))

  # Define Qt-specific flags based on sanitized target flags
  QT_CFLAGS = -O2 -fdiagnostics-format=msvc -pipe $(_SANITIZED_TARGET_CFLAGS) -fno-PIC
  QT_CXXFLAGS = -O2 -fdiagnostics-format=msvc -pipe $(_SANITIZED_TARGET_CXXFLAGS) -fno-PIC
  QT_LDFLAGS = -Wl,--no-insert-timestamp $(TARGET_LDFLAGS)

  # Ensure Qt's configure script is told it's cross-compiling for win32-g++
  $(package)_config_opts += -xplatform win32-g++

  # Directly set qmake variables to use sanitized flags
  $(package)_config_opts += \
    'QMAKE_CFLAGS=$$(QT_CFLAGS)' \
    'QMAKE_CXXFLAGS=$$(QT_CXXFLAGS)' \
    'QMAKE_LFLAGS=$$(QT_LDFLAGS)' \
    'QMAKE_CFLAGS_RELEASE=$$(QT_CFLAGS)' \
    'QMAKE_CXXFLAGS_RELEASE=$$(QT_CXXFLAGS)' \
    'QMAKE_LFLAGS_RELEASE=$$(QT_LDFLAGS)' \
    'QMAKE_CFLAGS_DEBUG=$$(QT_CFLAGS) -g' \
    'QMAKE_CXXFLAGS_DEBUG=$$(QT_CXXFLAGS) -g' \
    'QMAKE_LFLAGS_DEBUG=$$(QT_LDFLAGS)'

  # Add -no-framework for MinGW builds to avoid linking against macOS frameworks
  $(package)_config_opts += -no-framework

  # Additional MinGW-specific options
  $(package)_config_opts += -device-option CROSS_COMPILE=$(HOST)-
endif

endef

define $(package)_fetch_cmds
$(call fetch_file,$(package),$($(package)_download_path),$($(package)_download_file),$($(package)_file_name),$($(package)_sha256_hash))
endef

define $(package)_extract_cmds
  mkdir -p $($(package)_extract_dir) && \
  echo "$($(package)_sha256_hash)  $($(package)_source)" > $($(package)_extract_dir)/.$($(package)_file_name).hash && \
  tar --no-same-owner --strip-components=1 -xf $($(package)_source)
endef

define $(package)_preprocess_cmds
  sed -i.old "s|updateqm.commands = \$$$$\$$$$LRELEASE|updateqm.commands = $($(package)_extract_dir)/qttools/bin/lrelease|" qttranslations/translations/translations.pro && \
  sed -i.old "/updateqm.depends =/d" qttranslations/translations/translations.pro && \
  sed -i.old "s/src_plugins.depends = src_sql src_network src_xml src_testlib/src_plugins.depends = src_network/" qtbase/src/src.pro && \
  sed -i.old "s|X11/extensions/XIproto.h|X11/X.h|" qtbase/src/plugins/platforms/xcb/qxcbxsettings.cpp && \
  sed -i.old 's/if \[ "$$$$XPLATFORM_MAC" = "yes" \]; then xspecvals=$$$$(macSDKify/if \[ "$$$$BUILD_ON_MAC" = "yes" \]; then xspecvals=$$$$(macSDKify/' qtbase/configure && \
  mkdir -p qtbase/mkspecs/macx-clang-linux && \
  cp -f qtbase/mkspecs/macx-clang/Info.plist.lib qtbase/mkspecs/macx-clang-linux/ && \
  cp -f qtbase/mkspecs/macx-clang/Info.plist.app qtbase/mkspecs/macx-clang-linux/ && \
  cp -f qtbase/mkspecs/macx-clang/qmake.conf qtbase/mkspecs/macx-clang-linux/ && \
  cp -f qtbase/mkspecs/macx-clang/qplatformdefs.h qtbase/mkspecs/macx-clang-linux/ && \
  sed -i.old "s/QMAKE_MACOSX_DEPLOYMENT_TARGET      = 10.7/QMAKE_MACOSX_DEPLOYMENT_TARGET      = $(OSX_MIN_VERSION)/" qtbase/mkspecs/macx-clang-linux/qmake.conf
endef

define $(package)_config_cmds
  export PKG_CONFIG_SYSROOT_DIR=/ && \
  export PKG_CONFIG_LIBDIR=$(host_prefix)/lib/pkgconfig && \
  export PKG_CONFIG_PATH=$(host_prefix)/lib/pkgconfig && \
  ./configure $($(package)_config_opts)
endef

define $(package)_build_cmds
  $(MAKE)
endef

define $(package)_stage_cmds
  $(MAKE) INSTALL_ROOT=$($(package)_staging_dir) install
endef
EOF

echo -e "${GREEN}✅ qt.mk fixed with DeepResearch recommendations${NC}"

# Step 4: Fix depends/packages/libevent.mk for Windows compatibility
echo -e "\n${YELLOW}Step 4: Fixing libevent.mk for Windows...${NC}"

# Create patch directory if it doesn't exist
mkdir -p depends/patches/libevent

# Create the sys/uio.h compatibility patch
cat > depends/patches/libevent/0001-mingw-sysuio-compat.patch << 'EOF'
--- a/evutil.c
+++ b/evutil.c
@@ -60,7 +60,15 @@
 #include <sys/stat.h>
 #endif
 
+#if (defined(__MINGW32__) || defined(_WIN32)) && !defined(SYS_UIO_H)
+#define SYS_UIO_H
+struct iovec {
+    void *iov_base; /* Base address. */
+    size_t iov_len; /* Length. */
+};
+#else
 #include <sys/uio.h>
+#endif
 
 #include "event2/event-config.h"
 #include "event2/util.h"
EOF

# Update libevent.mk to apply the patch
if [ -f depends/packages/libevent.mk ]; then
    cp depends/packages/libevent.mk depends/packages/libevent.mk.backup
    
    # Add patch to libevent.mk if not already present
    if ! grep -q "0001-mingw-sysuio-compat.patch" depends/packages/libevent.mk; then
        sed -i.bak '/$(package)_patches/d' depends/packages/libevent.mk
        echo '$(package)_patches = 0001-mingw-sysuio-compat.patch' >> depends/packages/libevent.mk
    fi
fi

echo -e "${GREEN}✅ libevent.mk fixed for Windows compatibility${NC}"

# Step 5: Build dependencies with sanitized environment
echo -e "\n${YELLOW}Step 5: Building dependencies with sanitized environment...${NC}"

cd depends

# Clear potentially interfering environment variables (DeepResearch recommendation)
export CFLAGS=""
export CXXFLAGS=""
export LDFLAGS=""
export CC=""
export CXX=""

echo "Building dependencies for $HOST..."
echo "This may take 30-60 minutes depending on your system..."

# Build all dependencies
if ! make HOST=${HOST} -j${NCPU}; then
    echo -e "${RED}❌ Dependencies build failed${NC}"
    echo "Trying to build Qt separately for debugging..."
    
    # Try building Qt separately with verbose output
    make HOST=${HOST} V=1 qt 2>&1 | tee qt_build.log
    
    echo -e "${RED}Qt build failed. Check qt_build.log for details.${NC}"
    exit 1
fi

cd ..

echo -e "${GREEN}✅ Dependencies built successfully${NC}"

# Step 6: Configure main project
echo -e "\n${YELLOW}Step 6: Configuring main project...${NC}"

# Generate configure script if needed
if [ ! -f configure ]; then
    ./autogen.sh
fi

# Configure with proper CONFIG_SITE
CONFIG_SITE="$PWD/depends/${HOST}/share/config.site" \
./configure \
    --prefix=/ \
    --enable-gui \
    --with-gui=qt5 \
    --disable-tests \
    --disable-bench \
    --disable-man \
    --disable-shared \
    --enable-static \
    CXXFLAGS="-O2 -g" \
    CFLAGS="-O2 -g"

echo -e "${GREEN}✅ Project configured successfully${NC}"

# Step 7: Build main project
echo -e "\n${YELLOW}Step 7: Building main project...${NC}"

if ! make -j${NCPU}; then
    echo -e "${RED}❌ Main project build failed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Main project built successfully${NC}"

# Step 8: Collect Windows GUI files
echo -e "\n${YELLOW}Step 8: Collecting Windows GUI files...${NC}"

# Create output directory
OUTPUT_DIR="Krepto-Windows-GUI-v2"
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# Copy main executables with proper naming
if [ -f src/qt/bitcoin-qt.exe ]; then
    cp src/qt/bitcoin-qt.exe "$OUTPUT_DIR/krepto-qt.exe"
    echo -e "${GREEN}✅ krepto-qt.exe created${NC}"
else
    echo -e "${RED}❌ bitcoin-qt.exe not found${NC}"
    exit 1
fi

if [ -f src/bitcoind.exe ]; then
    cp src/bitcoind.exe "$OUTPUT_DIR/kryptod.exe"
    echo -e "${GREEN}✅ kryptod.exe created${NC}"
fi

if [ -f src/bitcoin-cli.exe ]; then
    cp src/bitcoin-cli.exe "$OUTPUT_DIR/krepto-cli.exe"
    echo -e "${GREEN}✅ krepto-cli.exe created${NC}"
fi

# Copy other utilities
for util in bitcoin-tx bitcoin-util bitcoin-wallet; do
    if [ -f "src/${util}.exe" ]; then
        cp "src/${util}.exe" "$OUTPUT_DIR/krepto-${util#bitcoin-}.exe"
        echo -e "${GREEN}✅ krepto-${util#bitcoin-}.exe created${NC}"
    fi
done

# Copy Qt5 DLLs and dependencies
DEPENDS_PREFIX="depends/${HOST}"

echo "Copying Qt5 DLLs..."
for dll in Qt5Core Qt5Gui Qt5Widgets Qt5Network; do
    if [ -f "${DEPENDS_PREFIX}/bin/${dll}.dll" ]; then
        cp "${DEPENDS_PREFIX}/bin/${dll}.dll" "$OUTPUT_DIR/"
        echo "  ✅ ${dll}.dll"
    fi
done

# Copy Qt plugins
if [ -d "${DEPENDS_PREFIX}/plugins" ]; then
    cp -r "${DEPENDS_PREFIX}/plugins" "$OUTPUT_DIR/"
    echo -e "${GREEN}✅ Qt plugins copied${NC}"
fi

# Copy MinGW runtime DLLs
echo "Copying MinGW runtime DLLs..."
MINGW_BIN="/opt/homebrew/Cellar/mingw-w64/*/toolchain-x86_64/x86_64-w64-mingw32/bin"
for dll in libgcc_s_seh-1.dll libstdc++-6.dll libwinpthread-1.dll; do
    DLL_PATH=$(find $MINGW_BIN -name "$dll" 2>/dev/null | head -1)
    if [ -f "$DLL_PATH" ]; then
        cp "$DLL_PATH" "$OUTPUT_DIR/"
        echo "  ✅ $dll"
    fi
done

# Create configuration file
cat > "$OUTPUT_DIR/bitcoin.conf" << EOF
# Krepto Configuration
rpcport=12347
port=12345

# Seed nodes
addnode=164.68.117.90:12345
connect=164.68.117.90:12345
addnode=5.189.133.204:12345
connect=5.189.133.204:12345

# Basic settings
server=1
daemon=1
txindex=1
EOF

# Create README
cat > "$OUTPUT_DIR/README.txt" << EOF
Krepto Windows GUI v2.0
========================

This package contains the Windows GUI version of Krepto cryptocurrency.

Files included:
- krepto-qt.exe     - Main GUI application
- kryptod.exe       - Daemon (background service)
- krepto-cli.exe    - Command line interface
- krepto-tx.exe     - Transaction utility
- krepto-util.exe   - General utility
- krepto-wallet.exe - Wallet utility
- Qt5*.dll          - Qt5 GUI libraries
- plugins/          - Qt5 plugins
- *.dll             - MinGW runtime libraries
- bitcoin.conf      - Configuration file

Quick Start:
1. Double-click krepto-qt.exe to start the GUI
2. The application will automatically connect to the Krepto network
3. Use Tools -> Mining Console to start mining

Network Information:
- Network: Krepto Mainnet
- Port: 12345
- RPC Port: 12347
- Seed Nodes: 164.68.117.90:12345, 5.189.133.204:12345

For support, visit: https://github.com/krepto/krepto
EOF

# Create batch file for easy startup
cat > "$OUTPUT_DIR/Start-Krepto-GUI.bat" << EOF
@echo off
echo Starting Krepto GUI...
krepto-qt.exe
pause
EOF

# Step 9: Create ZIP package
echo -e "\n${YELLOW}Step 9: Creating ZIP package...${NC}"

zip -r "${OUTPUT_DIR}.zip" "$OUTPUT_DIR"

# Calculate checksums
echo -e "\n${YELLOW}Step 10: Calculating checksums...${NC}"
SHA256=$(shasum -a 256 "${OUTPUT_DIR}.zip" | awk '{print $1}')
MD5=$(md5 -q "${OUTPUT_DIR}.zip")

echo -e "\n${GREEN}🎉 Windows GUI Build Complete!${NC}"
echo "=================================="
echo -e "${BLUE}Package:${NC} ${OUTPUT_DIR}.zip"
echo -e "${BLUE}Size:${NC} $(du -h "${OUTPUT_DIR}.zip" | awk '{print $1}')"
echo -e "${BLUE}SHA256:${NC} $SHA256"
echo -e "${BLUE}MD5:${NC} $MD5"

echo -e "\n${BLUE}Files in package:${NC}"
ls -la "$OUTPUT_DIR"

echo -e "\n${GREEN}✅ Ready for Windows deployment!${NC}"
echo -e "${YELLOW}Note: Test on Windows system before distribution${NC}" 