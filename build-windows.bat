@echo off
REM Krepto Windows Build Script
REM This script builds Krepto for Windows using Visual Studio and vcpkg

echo ========================================
echo    Krepto Windows Build Script
echo ========================================
echo.

REM Check if we're in the right directory
if not exist "src\main.cpp" (
    echo ERROR: This script must be run from the Krepto source directory
    echo Please navigate to the directory containing src\main.cpp
    pause
    exit /b 1
)

echo Step 1: Setting up environment...
set VCPKG_ROOT=C:\vcpkg
set VCPKG_DEFAULT_TRIPLET=x64-windows-static

REM Check if vcpkg is installed
if not exist "%VCPKG_ROOT%\vcpkg.exe" (
    echo Installing vcpkg...
    git clone https://github.com/Microsoft/vcpkg.git C:\vcpkg
    cd /d C:\vcpkg
    call bootstrap-vcpkg.bat
    vcpkg integrate install
    cd /d %~dp0
)

echo Step 2: Installing dependencies...
%VCPKG_ROOT%\vcpkg.exe install boost:x64-windows-static
%VCPKG_ROOT%\vcpkg.exe install libevent:x64-windows-static
%VCPKG_ROOT%\vcpkg.exe install openssl:x64-windows-static
%VCPKG_ROOT%\vcpkg.exe install berkeleydb:x64-windows-static
%VCPKG_ROOT%\vcpkg.exe install qt5-base:x64-windows-static
%VCPKG_ROOT%\vcpkg.exe install qt5-tools:x64-windows-static
%VCPKG_ROOT%\vcpkg.exe install qt5-winextras:x64-windows-static

echo Step 3: Generating project files...
python build_msvc\msvc-autogen.py

echo Step 4: Building Krepto...
REM Use MSBuild to build the solution
"C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe" build_msvc\bitcoin.sln -property:Configuration=Release -property:Platform=x64 -maxCpuCount

if %ERRORLEVEL% neq 0 (
    echo Build failed!
    pause
    exit /b 1
)

echo Step 5: Creating distribution package...
if exist Krepto-Windows-Release rmdir /s /q Krepto-Windows-Release
mkdir Krepto-Windows-Release

REM Copy executables
copy build_msvc\x64\Release\bitcoin-qt.exe Krepto-Windows-Release\krepto-qt.exe
copy build_msvc\x64\Release\bitcoind.exe Krepto-Windows-Release\kryptod.exe
copy build_msvc\x64\Release\bitcoin-cli.exe Krepto-Windows-Release\krepto-cli.exe
copy build_msvc\x64\Release\bitcoin-tx.exe Krepto-Windows-Release\krepto-tx.exe
copy build_msvc\x64\Release\bitcoin-util.exe Krepto-Windows-Release\krepto-util.exe
copy build_msvc\x64\Release\bitcoin-wallet.exe Krepto-Windows-Release\krepto-wallet.exe

REM Create configuration file
echo # Krepto Configuration > Krepto-Windows-Release\krepto.conf
echo # Network settings >> Krepto-Windows-Release\krepto.conf
echo port=12345 >> Krepto-Windows-Release\krepto.conf
echo rpcport=12347 >> Krepto-Windows-Release\krepto.conf
echo. >> Krepto-Windows-Release\krepto.conf
echo # Seed nodes >> Krepto-Windows-Release\krepto.conf
echo addnode=164.68.117.90:12345 >> Krepto-Windows-Release\krepto.conf
echo addnode=5.189.133.204:12345 >> Krepto-Windows-Release\krepto.conf
echo. >> Krepto-Windows-Release\krepto.conf
echo # RPC settings >> Krepto-Windows-Release\krepto.conf
echo rpcuser=kreptouser >> Krepto-Windows-Release\krepto.conf
echo rpcpassword=kreptopass123 >> Krepto-Windows-Release\krepto.conf
echo rpcallowip=127.0.0.1 >> Krepto-Windows-Release\krepto.conf
echo. >> Krepto-Windows-Release\krepto.conf
echo # Basic settings >> Krepto-Windows-Release\krepto.conf
echo server=1 >> Krepto-Windows-Release\krepto.conf
echo listen=1 >> Krepto-Windows-Release\krepto.conf
echo txindex=1 >> Krepto-Windows-Release\krepto.conf

REM Create README
echo Krepto Windows Release > Krepto-Windows-Release\README.txt
echo ====================== >> Krepto-Windows-Release\README.txt
echo. >> Krepto-Windows-Release\README.txt
echo This package contains Krepto cryptocurrency for Windows. >> Krepto-Windows-Release\README.txt
echo. >> Krepto-Windows-Release\README.txt
echo Files: >> Krepto-Windows-Release\README.txt
echo - krepto-qt.exe     : GUI application >> Krepto-Windows-Release\README.txt
echo - kryptod.exe       : Daemon/server >> Krepto-Windows-Release\README.txt
echo - krepto-cli.exe    : Command line interface >> Krepto-Windows-Release\README.txt
echo - krepto-tx.exe     : Transaction utility >> Krepto-Windows-Release\README.txt
echo - krepto-util.exe   : General utility >> Krepto-Windows-Release\README.txt
echo - krepto-wallet.exe : Wallet utility >> Krepto-Windows-Release\README.txt
echo - krepto.conf       : Configuration file >> Krepto-Windows-Release\README.txt
echo. >> Krepto-Windows-Release\README.txt
echo Quick Start: >> Krepto-Windows-Release\README.txt
echo 1. Double-click krepto-qt.exe to start the GUI >> Krepto-Windows-Release\README.txt
echo 2. The application will connect to the Krepto network >> Krepto-Windows-Release\README.txt
echo 3. Use Tools -^> Mining Console to start mining >> Krepto-Windows-Release\README.txt
echo. >> Krepto-Windows-Release\README.txt
echo Network: >> Krepto-Windows-Release\README.txt
echo - Main port: 12345 >> Krepto-Windows-Release\README.txt
echo - RPC port: 12347 >> Krepto-Windows-Release\README.txt
echo - Seed nodes: 164.68.117.90:12345, 5.189.133.204:12345 >> Krepto-Windows-Release\README.txt

REM Create startup batch file
echo @echo off > Krepto-Windows-Release\Start-Krepto-GUI.bat
echo echo Starting Krepto GUI... >> Krepto-Windows-Release\Start-Krepto-GUI.bat
echo echo Network: Krepto Mainnet >> Krepto-Windows-Release\Start-Krepto-GUI.bat
echo echo Port: 12345 >> Krepto-Windows-Release\Start-Krepto-GUI.bat
echo echo. >> Krepto-Windows-Release\Start-Krepto-GUI.bat
echo krepto-qt.exe >> Krepto-Windows-Release\Start-Krepto-GUI.bat

echo.
echo ========================================
echo    Build completed successfully!
echo ========================================
echo.
echo Package created: Krepto-Windows-Release\
echo.
echo To create a ZIP file, run:
echo powershell Compress-Archive -Path "Krepto-Windows-Release\*" -DestinationPath "Krepto-Windows-v1.0.0.zip"
echo.
pause 