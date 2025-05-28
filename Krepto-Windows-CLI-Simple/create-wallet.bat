@echo off
echo Creating new Krepto wallet...
krepto-cli.exe createwallet "default"
echo Wallet created successfully!
echo Getting new address...
krepto-cli.exe getnewaddress
pause
