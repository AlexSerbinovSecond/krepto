# 🚀 Krepto Mining Guide

Krepto is a Bitcoin fork with the ticker "KREPTO". This guide explains how to mine Krepto coins.

## 🎯 Quick Start

### Option 1: Interactive Mining Setup
```bash
./start_mining.sh
```
This script will guide you through the mining setup process.

### Option 2: Continuous Mining
```bash
./mine_krepto.sh [address] [blocks_per_batch]
```

### Option 3: Manual Mining
```bash
# Mine 1 block to a specific address
./src/bitcoin-cli -datadir=/Users/serbinov/.krepto -rpcport=12347 generatetoaddress 1 kr1qyd9fkjjacagwha4l4548q02glxt9w88rxpuyr3 10000000

# Mine 5 blocks
./src/bitcoin-cli -datadir=/Users/serbinov/.krepto -rpcport=12347 generatetoaddress 5 kr1qyd9fkjjacagwha4l4548q02glxt9w88rxpuyr3 10000000
```

## 📋 Prerequisites

1. **Krepto daemon must be running:**
   ```bash
   ./src/bitcoind -datadir=/Users/serbinov/.krepto -daemon
   ```

2. **Create a wallet (if not exists):**
   ```bash
   ./src/bitcoin-cli -datadir=/Users/serbinov/.krepto -rpcport=12347 createwallet "mining_wallet"
   ```

3. **Get a mining address:**
   ```bash
   ./src/bitcoin-cli -datadir=/Users/serbinov/.krepto -rpcport=12347 getnewaddress "mining"
   ```

## ⚙️ Mining Parameters

- **Block Reward:** 50 KREPTO per block
- **Block Time:** Variable (depends on difficulty)
- **Difficulty:** 0.000244140625 (current)
- **Maturation:** 100 blocks (coins become spendable after 100 confirmations)
- **Max Tries:** 10,000,000 (recommended for reliable mining)

## 🔧 Configuration

### Network Settings
- **Main Port:** 12345
- **RPC Port:** 12347
- **Data Directory:** `/Users/serbinov/.krepto`
- **Magic Bytes:** 0x4b, 0x52, 0x45, 0x50 (KREP)

### Genesis Block
- **Hash:** `00000d2843e19d3f61aaf31f1f919a1be17fc1b814d43117f8f8a4b602a559f2`
- **Timestamp:** 1748270717
- **Phrase:** "Crypto is now Krepto"

## 📊 Monitoring

### Check Blockchain Status
```bash
./src/bitcoin-cli -datadir=/Users/serbinov/.krepto -rpcport=12347 getblockchaininfo
```

### Check Mining Balance
```bash
./src/bitcoin-cli -datadir=/Users/serbinov/.krepto -rpcport=12347 getbalance
```

### Check Network Info
```bash
./src/bitcoin-cli -datadir=/Users/serbinov/.krepto -rpcport=12347 getnetworkinfo
```

### Get Mining Info
```bash
./src/bitcoin-cli -datadir=/Users/serbinov/.krepto -rpcport=12347 getmininginfo
```

## 🎮 GUI Mining

You can also mine using the GUI:

1. **Start GUI:**
   ```bash
   ./src/qt/bitcoin-qt -datadir=/Users/serbinov/.krepto -conf=/Users/serbinov/.krepto/bitcoin.conf
   ```

2. **Open Debug Console:** Help → Debug Window → Console

3. **Mine blocks:**
   ```javascript
   generatetoaddress 1 kr1qyd9fkjjacagwha4l4548q02glxt9w88rxpuyr3 10000000
   ```

## 🚨 Important Notes

### Why `max_tries` is Important
The `generatetoaddress` command has a `max_tries` parameter (default: 1,000,000). For Krepto's current difficulty, this is often not enough. **Always use 10,000,000 or higher** for reliable mining.

### Mining Success Rate
- ✅ **With 10,000,000 max_tries:** ~100% success rate
- ❌ **With 1,000,000 max_tries:** ~10% success rate (returns empty array `[]`)

### Example of Failed Mining
```bash
# This often fails (returns [])
generatetoaddress 1 kr1qyd9fkjjacagwha4l4548q02glxt9w88rxpuyr3

# This works reliably
generatetoaddress 1 kr1qyd9fkjjacagwha4l4548q02glxt9w88rxpuyr3 10000000
```

## 📈 Mining Performance

Current mining performance on MacBook Pro:
- **Rate:** ~5,400 blocks/hour
- **Time per block:** ~0.67 seconds
- **Success rate:** 100% (with proper max_tries)

## 🛠️ Troubleshooting

### Daemon Not Running
```bash
# Check if running
ps aux | grep bitcoind

# Start daemon
./src/bitcoind -datadir=/Users/serbinov/.krepto -daemon

# Check logs
tail -f /Users/serbinov/.krepto/debug.log
```

### Mining Returns Empty Array
This means `max_tries` was reached without finding a block. Increase the value:
```bash
generatetoaddress 1 your_address 50000000
```

### Wallet Not Found
```bash
# List wallets
./src/bitcoin-cli -datadir=/Users/serbinov/.krepto -rpcport=12347 listwallets

# Create wallet
./src/bitcoin-cli -datadir=/Users/serbinov/.krepto -rpcport=12347 createwallet "mining_wallet"

# Load wallet
./src/bitcoin-cli -datadir=/Users/serbinov/.krepto -rpcport=12347 loadwallet "mining_wallet"
```

## 🎯 Mining Strategies

### For Testing
```bash
# Mine 1 block quickly
./src/bitcoin-cli -datadir=/Users/serbinov/.krepto -rpcport=12347 generatetoaddress 1 your_address 10000000
```

### For Continuous Mining
```bash
# Use the continuous mining script
./mine_krepto.sh your_address 1
```

### For Batch Mining
```bash
# Mine 10 blocks at once
./src/bitcoin-cli -datadir=/Users/serbinov/.krepto -rpcport=12347 generatetoaddress 10 your_address 10000000
```

## 💡 Tips

1. **Always use high max_tries** (10M+) for reliable mining
2. **Monitor the logs** to see mining progress
3. **Use continuous mining script** for best experience
4. **Check balance regularly** to see your rewards
5. **Remember maturation period** - coins need 100 confirmations

---

Happy Mining! 🚀⛏️💰 