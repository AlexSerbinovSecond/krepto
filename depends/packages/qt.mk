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
