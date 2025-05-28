@echo off
echo Creating Krepto Wallet...
krepto-cli.exe -datadir=data -conf=bitcoin.conf createwallet "main"
echo.
echo Getting new address...
krepto-cli.exe -datadir=data -conf=bitcoin.conf getnewaddress
pause
