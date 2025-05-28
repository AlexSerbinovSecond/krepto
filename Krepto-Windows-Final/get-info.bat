@echo off
echo Getting Krepto blockchain info...
krypto-cli.exe getblockchaininfo
echo.
echo Getting wallet info...
krypto-cli.exe getwalletinfo
pause
