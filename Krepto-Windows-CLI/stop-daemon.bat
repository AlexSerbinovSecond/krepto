@echo off
echo Stopping Krepto Daemon...
krypto-cli.exe -datadir=%APPDATA%\Krepto stop
pause
