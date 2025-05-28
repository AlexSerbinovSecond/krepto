@echo off
echo Starting Krepto Mining...
echo Please enter your Krepto address:
set /p ADDRESS=Address: 
krepto-cli.exe -datadir=data -conf=bitcoin.conf generatetoaddress 1 %ADDRESS% 10000000
pause
