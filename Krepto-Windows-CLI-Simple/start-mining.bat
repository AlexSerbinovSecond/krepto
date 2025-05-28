@echo off
echo Starting Krepto mining...
echo First, let's get a mining address...
for /f "tokens=*" %%a in ('krepto-cli.exe getnewaddress') do set MINING_ADDRESS=%%a
echo Mining address: %MINING_ADDRESS%
echo.
echo Starting mining to address %MINING_ADDRESS%...
krepto-cli.exe generatetoaddress 1 %MINING_ADDRESS% 10000000
echo Mining completed! Check your balance with get-info.bat
pause
