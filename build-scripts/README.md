# 🔧 Krepto Build Scripts

This directory contains various build and deployment scripts for the Krepto project.

## 📦 DMG Build Scripts (macOS)

### Production Ready
- **`build_professional_dmg.sh`** - Main production DMG builder with code signing
- **`build_signed_dmg.sh`** - Professional DMG with full macOS integration

### Development/Testing
- **`build_dmg.sh`** - Basic DMG builder
- **`build_simple_dmg.sh`** - Simplified DMG creation
- **`build_standalone_dmg.sh`** - Standalone application DMG
- **`build_qt_dmg.sh`** - Qt-based DMG builder
- **`build_qt_dmg_fixed.sh`** - Fixed version of Qt DMG builder
- **`build_hybrid_dmg.sh`** - Hybrid build approach

## 🪟 Windows Build Scripts

### GUI Builds
- **`build_windows_gui.sh`** - Main Windows GUI builder
- **`build_windows_gui_simple.sh`** - Simplified Windows GUI build
- **`build_windows_gui_fixed.sh`** - Fixed Windows GUI build
- **`build_windows_gui_fixed_v2.sh`** - Version 2 of fixed build
- **`build_windows_gui_docker.sh`** - Docker-based Windows build
- **`build_windows_gui_autotools.sh`** - Autotools-based Windows build
- **`build_windows_gui_system_qt.sh`** - System Qt Windows build
- **`build_windows_gui_alternative.sh`** - Alternative Windows build method

### CLI Builds
- **`build_windows_cli_only.sh`** - Windows CLI-only build
- **`build_windows_simple.sh`** - Simple Windows build
- **`build_windows_final.sh`** - Final Windows build script

### Packaging
- **`build_windows_installer.sh`** - Windows installer creation
- **`create_windows_package.sh`** - Windows package creator

## ⛏️ Mining Scripts

- **`mine_krepto.sh`** - Basic Krepto mining script
- **`mine_krepto_gui.sh`** - GUI-based mining script
- **`mine_krepto_server.sh`** - Server mining script
- **`mine_krepto_adaptive.sh`** - Adaptive mining with difficulty adjustment
- **`start_mining.sh`** - Quick mining starter

## 🌐 Network Scripts

- **`test_seed_nodes.sh`** - Test connectivity to seed nodes

## 🔍 Utility Scripts

- **`get_github_logs.sh`** - Fetch GitHub Actions logs

## 📝 Usage Examples

### Build macOS DMG
```bash
cd build-scripts
./build_professional_dmg.sh
```

### Build Windows GUI
```bash
cd build-scripts
./build_windows_gui.sh
```

### Start Mining
```bash
cd build-scripts
./start_mining.sh
```

### Test Network
```bash
cd build-scripts
./test_seed_nodes.sh
```

## ⚠️ Notes

- Most scripts require the main Krepto to be compiled first
- Windows builds may require cross-compilation tools (MXE, Docker, etc.)
- DMG scripts require macOS and proper code signing certificates
- Always test scripts in development environment first

## 🏗️ Main Build Process

For regular users, the main build process is:
```bash
# From krepto root directory
./autogen.sh
./configure
make -j8
```

These scripts are primarily for:
- Creating distribution packages
- Cross-platform builds  
- Automated CI/CD
- Development testing 