🚀 Krepto - Bitcoin Fork for Windows (CLI Version)

INSTALLATION:
1. Extract all files to a folder (e.g., C:\Krepto)
2. Copy bitcoin.conf to %APPDATA%\Krepto\
3. Run start-daemon.bat to start the daemon

EXECUTABLES:
- kryptod.exe - Main daemon
- krypto-cli.exe - Command line interface
- krypto-tx.exe - Transaction tools
- krypto-util.exe - Utility tools

BATCH FILES:
- start-daemon.bat - Start Krepto daemon
- stop-daemon.bat - Stop Krepto daemon
- get-info.bat - Show network and wallet info
- start-mining.bat - Start mining Krepto

NETWORK INFO:
- Krepto uses its own blockchain (not Bitcoin)
- Connects to seed node: 164.68.117.90:12345
- Data stored in: %APPDATA%\Krepto\
- Addresses start with 'K' (legacy) or 'kr1q' (SegWit)

FEATURES:
- Command line mining
- SegWit support from genesis
- Fast block generation
- Compatible with Bitcoin Core RPC

CONFIGURATION:
- Config file: %APPDATA%\Krepto\bitcoin.conf
- Logs: %APPDATA%\Krepto\debug.log
- Network: Krepto mainnet (port 12345)

MINING:
1. Run start-daemon.bat
2. Wait for synchronization
3. Run start-mining.bat
4. Enjoy mining Krepto! ⛏️

COMMANDS:
- krypto-cli.exe getblockchaininfo
- krypto-cli.exe getwalletinfo
- krypto-cli.exe getnewaddress
- krypto-cli.exe generatetoaddress 1 <address> 10000000

SUPPORT:
- Check %APPDATA%\Krepto\debug.log for troubleshooting
- Ensure port 12345 is not blocked by firewall
- For help, check the configuration file

Enjoy mining Krepto! 🎉
