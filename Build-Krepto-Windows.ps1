# Krepto Windows Build Script (PowerShell)
# This script builds Krepto for Windows using Visual Studio and vcpkg

param(
    [string]$Configuration = "Release",
    [string]$Platform = "x64",
    [string]$VcpkgRoot = "C:\vcpkg"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "    Krepto Windows Build Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if we're in the right directory
if (-not (Test-Path "src\main.cpp")) {
    Write-Host "ERROR: This script must be run from the Krepto source directory" -ForegroundColor Red
    Write-Host "Please navigate to the directory containing src\main.cpp" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "Step 1: Setting up environment..." -ForegroundColor Green
$env:VCPKG_ROOT = $VcpkgRoot
$env:VCPKG_DEFAULT_TRIPLET = "$Platform-windows-static"

# Check if vcpkg is installed
if (-not (Test-Path "$VcpkgRoot\vcpkg.exe")) {
    Write-Host "Installing vcpkg..." -ForegroundColor Yellow
    git clone https://github.com/Microsoft/vcpkg.git $VcpkgRoot
    Set-Location $VcpkgRoot
    .\bootstrap-vcpkg.bat
    .\vcpkg.exe integrate install
    Set-Location $PSScriptRoot
}

Write-Host "Step 2: Installing dependencies..." -ForegroundColor Green
$dependencies = @(
    "boost:$Platform-windows-static",
    "libevent:$Platform-windows-static", 
    "openssl:$Platform-windows-static",
    "berkeleydb:$Platform-windows-static",
    "qt5-base:$Platform-windows-static",
    "qt5-tools:$Platform-windows-static",
    "qt5-winextras:$Platform-windows-static"
)

foreach ($dep in $dependencies) {
    Write-Host "Installing $dep..." -ForegroundColor Yellow
    & "$VcpkgRoot\vcpkg.exe" install $dep
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to install $dep" -ForegroundColor Red
        exit 1
    }
}

Write-Host "Step 3: Generating project files..." -ForegroundColor Green
python build_msvc\msvc-autogen.py
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to generate project files" -ForegroundColor Red
    exit 1
}

Write-Host "Step 4: Building Krepto..." -ForegroundColor Green
# Find MSBuild
$msbuildPaths = @(
    "C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe",
    "C:\Program Files\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\MSBuild.exe",
    "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\MSBuild.exe",
    "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\MSBuild\Current\Bin\MSBuild.exe",
    "C:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\MSBuild\Current\Bin\MSBuild.exe",
    "C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\MSBuild\Current\Bin\MSBuild.exe"
)

$msbuild = $null
foreach ($path in $msbuildPaths) {
    if (Test-Path $path) {
        $msbuild = $path
        break
    }
}

if (-not $msbuild) {
    Write-Host "ERROR: MSBuild not found. Please install Visual Studio 2019 or 2022." -ForegroundColor Red
    exit 1
}

Write-Host "Using MSBuild: $msbuild" -ForegroundColor Yellow

& $msbuild "build_msvc\bitcoin.sln" -property:Configuration=$Configuration -property:Platform=$Platform -maxCpuCount
if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "Step 5: Creating distribution package..." -ForegroundColor Green
$packageDir = "Krepto-Windows-Release"
if (Test-Path $packageDir) {
    Remove-Item $packageDir -Recurse -Force
}
New-Item -ItemType Directory -Path $packageDir | Out-Null

# Copy executables with proper naming
$executables = @{
    "build_msvc\$Platform\$Configuration\bitcoin-qt.exe" = "krepto-qt.exe"
    "build_msvc\$Platform\$Configuration\bitcoind.exe" = "kryptod.exe"
    "build_msvc\$Platform\$Configuration\bitcoin-cli.exe" = "krepto-cli.exe"
    "build_msvc\$Platform\$Configuration\bitcoin-tx.exe" = "krepto-tx.exe"
    "build_msvc\$Platform\$Configuration\bitcoin-util.exe" = "krepto-util.exe"
    "build_msvc\$Platform\$Configuration\bitcoin-wallet.exe" = "krepto-wallet.exe"
}

foreach ($source in $executables.Keys) {
    $target = $executables[$source]
    if (Test-Path $source) {
        Copy-Item $source "$packageDir\$target"
        Write-Host "✅ Copied $target" -ForegroundColor Green
    } else {
        Write-Host "⚠️  $source not found" -ForegroundColor Yellow
    }
}

# Create configuration file
$configContent = @"
# Krepto Configuration File
# Network settings
port=12345
rpcport=12347

# Seed nodes
addnode=164.68.117.90:12345
addnode=5.189.133.204:12345

# RPC settings
rpcuser=kreptouser
rpcpassword=kreptopass123
rpcallowip=127.0.0.1

# Basic settings
server=1
listen=1
txindex=1
"@

$configContent | Out-File -FilePath "$packageDir\krepto.conf" -Encoding UTF8

# Create README
$readmeContent = @"
Krepto Windows Release
======================

This package contains Krepto cryptocurrency for Windows.

Files:
- krepto-qt.exe     : GUI application
- kryptod.exe       : Daemon/server
- krepto-cli.exe    : Command line interface
- krepto-tx.exe     : Transaction utility
- krepto-util.exe   : General utility
- krepto-wallet.exe : Wallet utility
- krepto.conf       : Configuration file

Quick Start:
1. Double-click krepto-qt.exe to start the GUI
2. The application will connect to the Krepto network
3. Use Tools -> Mining Console to start mining

Network:
- Main port: 12345
- RPC port: 12347
- Seed nodes: 164.68.117.90:12345, 5.189.133.204:12345

System Requirements:
- Windows 10 or later (64-bit)
- 4GB RAM minimum
- 10GB free disk space

Built on: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss UTC')
"@

$readmeContent | Out-File -FilePath "$packageDir\README.txt" -Encoding UTF8

# Create startup batch file
$batchContent = @"
@echo off
echo Starting Krepto GUI...
echo Network: Krepto Mainnet
echo Port: 12345
echo.
krepto-qt.exe
pause
"@

$batchContent | Out-File -FilePath "$packageDir\Start-Krepto-GUI.bat" -Encoding ASCII

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "    Build completed successfully!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Package created: $packageDir\" -ForegroundColor Green
Write-Host ""

# Create ZIP package
$zipFile = "Krepto-Windows-v1.0.0.zip"
Write-Host "Creating ZIP package: $zipFile" -ForegroundColor Yellow
Compress-Archive -Path "$packageDir\*" -DestinationPath $zipFile -Force

if (Test-Path $zipFile) {
    $zipInfo = Get-Item $zipFile
    $zipSize = [math]::Round($zipInfo.Length / 1MB, 2)
    $zipHash = Get-FileHash $zipFile -Algorithm SHA256
    
    Write-Host ""
    Write-Host "✅ ZIP package created successfully!" -ForegroundColor Green
    Write-Host "📦 File: $zipFile" -ForegroundColor Cyan
    Write-Host "📏 Size: $zipSize MB" -ForegroundColor Cyan
    Write-Host "🔐 SHA256: $($zipHash.Hash)" -ForegroundColor Cyan
    
    # Save build info
    $buildInfo = @"
Package: $zipFile
Size: $zipSize MB
SHA256: $($zipHash.Hash)
Built: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss UTC')
Configuration: $Configuration
Platform: $Platform
"@
    $buildInfo | Out-File -FilePath "build-info.txt" -Encoding UTF8
    
    Write-Host ""
    Write-Host "Build information saved to: build-info.txt" -ForegroundColor Green
}

Write-Host ""
Write-Host "🎉 Krepto Windows build completed!" -ForegroundColor Green
Write-Host "" 