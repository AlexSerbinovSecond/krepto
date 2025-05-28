===========================================
    KREPTO - Windows CLI Distribution
===========================================

OVERVIEW:
Krepto is a Bitcoin-based cryptocurrency with fast mining and SegWit support.
This package contains all necessary tools to run Krepto on Windows.

INCLUDED FILES:
- kryptod.exe         : Main daemon (server)
- krepto-cli.exe      : Command line interface
- krepto-tx.exe       : Transaction utility
- krepto-util.exe     : General utility tool
- krepto-wallet.exe   : Wallet management tool
- bitcoin.conf        : Configuration file
- *.bat files         : Convenience scripts

QUICK START:
1. Double-click "start-daemon.bat" to start the Krepto daemon
2. Wait for synchronization with the network
3. Double-click "create-wallet.bat" to create your wallet
4. Use "get-info.bat" to check status
5. Use "start-mining.bat" to mine Krepto coins

NETWORK DETAILS:
- Network Port: 12345
- RPC Port: 12347
- Seed Nodes: 164.68.117.90:12345, 5.189.133.204:12345
- Data Directory: ./data/

MANUAL COMMANDS:
Start daemon:
  kryptod.exe -datadir=data -conf=bitcoin.conf

Get blockchain info:
  krepto-cli.exe -datadir=data -conf=bitcoin.conf getblockchaininfo

Create wallet:
  krepto-cli.exe -datadir=data -conf=bitcoin.conf createwallet "main"

Get new address:
  krepto-cli.exe -datadir=data -conf=bitcoin.conf getnewaddress

Mine blocks:
  krepto-cli.exe -datadir=data -conf=bitcoin.conf generatetoaddress 1 [YOUR_ADDRESS] 10000000

Stop daemon:
  krepto-cli.exe -datadir=data -conf=bitcoin.conf stop

SUPPORT:
For technical support and updates, visit the Krepto community.

===========================================
