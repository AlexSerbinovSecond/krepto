@echo off
echo Krepto Network Info:
krypto-cli.exe -datadir=%APPDATA%\Krepto getblockchaininfo
echo.
echo Wallet Info:
krypto-cli.exe -datadir=%APPDATA%\Krepto getwalletinfo
pause
