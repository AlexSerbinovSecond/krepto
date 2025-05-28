@echo off
echo Getting mining address...
for /f %%i in ('krypto-cli.exe -datadir=%APPDATA%\Krepto getnewaddress') do set ADDR=%%i
echo Mining to address: %ADDR%
echo Starting mining (press Ctrl+C to stop)...
krypto-cli.exe -datadir=%APPDATA%\Krepto generatetoaddress 1000000 %ADDR% 10000000
pause
