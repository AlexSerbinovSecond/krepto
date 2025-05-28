@echo off
echo Getting Krepto Network Info...
krepto-cli.exe -datadir=data -conf=bitcoin.conf getblockchaininfo
echo.
echo Getting Wallet Info...
krepto-cli.exe -datadir=data -conf=bitcoin.conf getwalletinfo
pause
