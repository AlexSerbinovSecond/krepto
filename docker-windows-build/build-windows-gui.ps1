# Krepto Windows Bitcoin Qt GUI Build Script
# Runs natively on Windows in Docker container

param(
    [string]$SourcePath = "C:\build\krepto",
    [string]$OutputPath = "C:\build\output"
)

Write-Host "🚀 Krepto Windows Bitcoin Qt GUI Build" -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor Green

# Function to check if command exists
function Test-Command($cmdname) {
    return [bool](Get-Command -Name $cmdname -ErrorAction SilentlyContinue)
}

# Verify build environment
Write-Host "🔧 Verifying build environment..." -ForegroundColor Yellow

# Check Visual Studio
if (-not (Test-Path "C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\Common7\Tools\VsDevCmd.bat")) {
    Write-Error "Visual Studio Build Tools 2019 not found!"
    exit 1
}

# Check Qt5
if (-not (Test-Path $env:QTDIR)) {
    Write-Error "Qt5 not found at $env:QTDIR"
    exit 1
}

# Check Git
if (-not (Test-Command "git")) {
    Write-Error "Git not found!"
    exit 1
}

Write-Host "✅ Build environment verified" -ForegroundColor Green

# Initialize Visual Studio environment
Write-Host "🔧 Initializing Visual Studio environment..." -ForegroundColor Yellow
cmd /c '"C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\Common7\Tools\VsDevCmd.bat" && set' | ForEach-Object {
    if ($_ -match "=") {
        $v = $_.split("=", 2)
        Set-Item -Force -Path "ENV:\$($v[0])" -Value "$($v[1])"
    }
}

# Clone or update source code
if (-not (Test-Path $SourcePath)) {
    Write-Host "📥 Cloning Krepto source code..." -ForegroundColor Yellow
    git clone https://github.com/user/krepto.git $SourcePath
} else {
    Write-Host "📥 Updating Krepto source code..." -ForegroundColor Yellow
    Set-Location $SourcePath
    git pull origin main
}

Set-Location $SourcePath

# Clean previous builds
Write-Host "🧹 Cleaning previous builds..." -ForegroundColor Yellow
if (Test-Path "build") {
    Remove-Item -Recurse -Force "build"
}
New-Item -ItemType Directory -Path "build" -Force | Out-Null

# Configure with CMake (alternative to autotools)
Write-Host "⚙️ Configuring build with CMake..." -ForegroundColor Yellow
Set-Location "build"

cmake .. `
    -G "Visual Studio 16 2019" `
    -A x64 `
    -DCMAKE_BUILD_TYPE=Release `
    -DBUILD_GUI=ON `
    -DBUILD_TESTS=OFF `
    -DBUILD_BENCH=OFF `
    -DWITH_WALLET=ON `
    -DWITH_ZMQ=OFF `
    -DQt5_DIR="$env:QTDIR\lib\cmake\Qt5" `
    -DQt5Core_DIR="$env:QTDIR\lib\cmake\Qt5Core" `
    -DQt5Widgets_DIR="$env:QTDIR\lib\cmake\Qt5Widgets" `
    -DQt5Gui_DIR="$env:QTDIR\lib\cmake\Qt5Gui" `
    -DQt5Network_DIR="$env:QTDIR\lib\cmake\Qt5Network" `
    -DCMAKE_PREFIX_PATH="$env:QTDIR"

if ($LASTEXITCODE -ne 0) {
    Write-Error "CMake configuration failed!"
    exit 1
}

Write-Host "✅ Configuration completed" -ForegroundColor Green

# Build the project
Write-Host "🔨 Building Bitcoin Qt GUI..." -ForegroundColor Yellow
Write-Host "This may take 30-60 minutes..." -ForegroundColor Yellow

cmake --build . --config Release --parallel 8

if ($LASTEXITCODE -ne 0) {
    Write-Error "Build failed!"
    exit 1
}

Write-Host "✅ Build completed successfully!" -ForegroundColor Green

# Create output directory
New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null

# Copy executables with proper naming
Write-Host "📦 Packaging executables..." -ForegroundColor Yellow

$executableMap = @{
    "src\Release\bitcoin-qt.exe" = "krepto-qt.exe"
    "src\Release\bitcoind.exe" = "kryptod.exe"
    "src\Release\bitcoin-cli.exe" = "krepto-cli.exe"
    "src\Release\bitcoin-tx.exe" = "krepto-tx.exe"
    "src\Release\bitcoin-util.exe" = "krepto-util.exe"
    "src\Release\bitcoin-wallet.exe" = "krepto-wallet.exe"
}

foreach ($source in $executableMap.Keys) {
    $target = $executableMap[$source]
    if (Test-Path $source) {
        Copy-Item $source "$OutputPath\$target"
        Write-Host "✅ $target created" -ForegroundColor Green
    } else {
        Write-Warning "⚠️ $source not found"
    }
}

# Copy Qt5 DLLs
Write-Host "📦 Copying Qt5 dependencies..." -ForegroundColor Yellow

$qtDlls = @(
    "Qt5Core.dll",
    "Qt5Gui.dll", 
    "Qt5Widgets.dll",
    "Qt5Network.dll"
)

foreach ($dll in $qtDlls) {
    $sourceDll = "$env:QTDIR\bin\$dll"
    if (Test-Path $sourceDll) {
        Copy-Item $sourceDll $OutputPath
        Write-Host "✅ $dll copied" -ForegroundColor Green
    }
}

# Copy Qt5 plugins
$pluginsPath = "$OutputPath\platforms"
New-Item -ItemType Directory -Path $pluginsPath -Force | Out-Null
Copy-Item "$env:QTDIR\plugins\platforms\qwindows.dll" $pluginsPath

# Copy Visual C++ Redistributable DLLs
Write-Host "📦 Copying Visual C++ runtime..." -ForegroundColor Yellow
$vcRedistPath = "C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Redist\MSVC\14.29.30133\x64\Microsoft.VC142.CRT"
if (Test-Path $vcRedistPath) {
    Copy-Item "$vcRedistPath\*.dll" $OutputPath
}

# Create configuration file
Write-Host "📝 Creating configuration file..." -ForegroundColor Yellow
$configContent = @"
# Krepto Configuration File
# Network settings
port=12345
rpcport=12347

# Seed nodes
addnode=164.68.117.90:12345
addnode=5.189.133.204:12345

# Basic settings
server=1
daemon=1
txindex=1

# RPC settings
rpcuser=kreptouser
rpcpassword=kreptopass123
rpcallowip=127.0.0.1
"@

$configContent | Out-File -FilePath "$OutputPath\bitcoin.conf" -Encoding UTF8

# Create README
Write-Host "📝 Creating README..." -ForegroundColor Yellow
$readmeContent = @"
Krepto Windows GUI Distribution
==============================

This package contains the Krepto cryptocurrency GUI and CLI tools for Windows.

Files included:
- krepto-qt.exe     : Graphical user interface (Bitcoin Qt GUI)
- kryptod.exe       : Daemon/server
- krepto-cli.exe    : Command line interface
- krepto-tx.exe     : Transaction utility
- krepto-util.exe   : General utility
- krepto-wallet.exe : Wallet utility
- Qt5*.dll          : Qt5 GUI libraries
- platforms/        : Qt5 platform plugins
- *.dll             : Visual C++ runtime libraries
- bitcoin.conf      : Configuration file

Quick Start:
1. Double-click krepto-qt.exe to start the GUI
2. The application will automatically connect to the Krepto network
3. Use Tools -> Mining Console to start mining

Network Information:
- Main network port: 12345
- RPC port: 12347
- Seed nodes: 164.68.117.90:12345, 5.189.133.204:12345
- Data directory: %APPDATA%\Krepto\

System Requirements:
- Windows 10 or later (64-bit)
- 4GB RAM minimum
- 10GB free disk space

For more information, visit: https://krepto.org
Built with Bitcoin Core Qt GUI technology.
"@

$readmeContent | Out-File -FilePath "$OutputPath\README.txt" -Encoding UTF8

# Create batch file for easy startup
$batchContent = @"
@echo off
echo Starting Krepto GUI...
echo.
echo Network: Krepto Mainnet
echo Port: 12345
echo.
krepto-qt.exe
pause
"@

$batchContent | Out-File -FilePath "$OutputPath\Start-Krepto-GUI.bat" -Encoding ASCII

# Create ZIP package
Write-Host "📦 Creating ZIP package..." -ForegroundColor Yellow
$zipPath = "C:\build\Krepto-Windows-GUI-Native.zip"
Compress-Archive -Path "$OutputPath\*" -DestinationPath $zipPath -Force

# Calculate file sizes and checksums
$zipInfo = Get-Item $zipPath
$zipSize = [math]::Round($zipInfo.Length / 1MB, 2)
$zipHash = Get-FileHash $zipPath -Algorithm SHA256

Write-Host ""
Write-Host "🎉 Windows Bitcoin Qt GUI build completed successfully!" -ForegroundColor Green
Write-Host "=======================================================" -ForegroundColor Green
Write-Host "Package: Krepto-Windows-GUI-Native.zip" -ForegroundColor Blue
Write-Host "Size: $zipSize MB" -ForegroundColor Blue
Write-Host "SHA256: $($zipHash.Hash)" -ForegroundColor Blue
Write-Host ""
Write-Host "Files in package:" -ForegroundColor Blue
Get-ChildItem $OutputPath | Format-Table Name, Length -AutoSize

Write-Host ""
Write-Host "✅ Ready for Windows deployment!" -ForegroundColor Green
Write-Host "📁 Output location: $zipPath" -ForegroundColor Yellow 