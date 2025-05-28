@echo off
echo Getting Krepto blockchain info...
krepto-cli.exe getblockchaininfo
echo.
echo Getting wallet info...
krepto-cli.exe getwalletinfo
pause
