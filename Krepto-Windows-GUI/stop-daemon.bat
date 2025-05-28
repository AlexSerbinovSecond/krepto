@echo off
echo Stopping Krepto Daemon...
krepto-cli.exe -datadir=data -conf=bitcoin.conf stop
pause
