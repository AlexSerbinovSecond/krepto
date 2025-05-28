@echo off
echo Creating new Krepto wallet...
krypto-cli.exe createwallet "default"
echo Wallet created successfully!
echo Getting new address...
krypto-cli.exe getnewaddress
pause
