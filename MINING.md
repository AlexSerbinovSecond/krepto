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
   ./src/qt/bitcoin-qt -datadir=/Users/serbinov/.krepto
   ```

2. **Open Mining Console:**
   1. Select **Tools** → **Mining Console**
   2. Or press the **Mining** button on the toolbar

3. **Start Mining:**
   1. Press **Start Mining**
   2. Monitor logs in real-time
   3. Statistics update automatically

## 📊 Mining Console Interface

### Main Elements

- **Start Mining** - Start Mining
- **Stop Mining** - Stop Mining  
- **Clear Log** - Clear Logs
- **Status** - Current Mining Status
- **Log Area** - Detailed Logs of the Process

### Statistics

- **Blocks Found** - Number of Blocks Found
- **Total Attempts** - Total Attempts
- **Hash Rate** - Current Hash Rate
- **Mining Address** - Address for Reward

## 🔧 How Mining Works

### Automatic Processes

1. **Address Creation**: GUI automatically creates a new address for mining
2. **RPC Calls**: Uses internal `generatetoaddress` commands
3. **Randomization**: Random delays and parameters for preventing conflicts
4. **Logging**: Detailed real-time statistics

### Technical Details

```cpp
// Internal RPC Call
UniValue params(UniValue::VARR);
params.push_back(1);                    // Number of blocks
params.push_back(miningAddress);        // Address for reward
UniValue result = clientModel->node().executeRpc("generatetoaddress", params, "");
```

## 📈 Mining Optimization

### Randomization Parameters

- **Max Tries**: 500,000 - 2,000,000 (randomized)
- **Delays**: 0-5 seconds between attempts
- **Addresses**: New addresses for each session

### Preventing Conflicts

If multiple clients are running:
- Each uses different parameters
- Random delays between attempts
- Unique mining addresses

## 🎮 Mining Example Session

```
=== MINING STARTED ===
Initializing mining process...
📊 Blockchain Info:
   Height: 4761 blocks
   Difficulty: 4.656542e-10
   Best block: 54df29b0b2ca9748bdd13daaf6cfedb4d8bff755f461e01e561485125124400b

🎯 Mining Configuration:
   Address: bc1qxyz...abc (fresh legacy address)
   Max tries: 1,247,832 (randomized)
   Delay: 2.3 seconds (randomized)

⛏️  Mining attempt #1...
✅ BLOCK FOUND! Hash: 00001234...5678
📦 Block #4762 mined successfully!
💰 Reward: 50 KREPTO

=== MINING STATISTICS ===
Total attempts: 1,247,832
Blocks found: 1
Success rate: 0.00008%
Hash rate: ~2.1 MH/s
```

## 🔍 Monitoring Progress

### Real-Time Logs

- **Blockchain Info**: Current Height and Difficulty
- **Mining Config**: Parameters of the Current Session
- **Attempts**: Number of Mining Attempts
- **Success**: Found Blocks and Rewards

### Statistics

- **Hash Rate**: Calculated Automatically
- **Success Rate**: Percentage of Successful Attempts
- **Time Tracking**: Mining Time

## 🛠️ Troubleshooting

### Mining Not Starting

**Symptom**: "Start Mining" button not responding

**Solution**:
1. Ensure GUI is fully loaded
2. Wait for blockchain synchronization
3. Restart GUI if necessary

### No Connections

**Symptom**: "No connections" in status

**Solution**:
1. Wait 1-2 minutes for automatic reconnection
2. Check internet connection
3. Restart client

### Low Speed

**Symptom**: Very low hash rate

**Solution**:
1. This is normal for CPU mining
2. Krepto optimized for accessibility
3. Difficulty automatically adjusts

## 📊 Expected Results

### Mining Speed

- **CPU Mining**: 1-10 MH/s (depending on processor)
- **Block Time**: ~10 minutes (average)
- **Difficulty**: Automatically Adjusts

### Rewards

- **Block reward**: 50 KREPTO per block
- **Halving**: Every 210,000 blocks
- **Fees**: Additional fees from transactions

## 🎯 Tips for Effective Mining

### Optimization

1. **Close other programs** for better performance
2. **Stable internet connection** for better synchronization
3. **Regular breaks** for cooling the system

### Monitoring

1. **Monitor logs** for identifying issues
2. **Check statistics** for evaluating effectiveness
3. **Keep backup** of wallet regularly

## 🏆 Successful Mining

When you find a block:
1. **Reward** automatically added to wallet
2. **Confirmation** appears after 100 blocks
3. **Balance** updated in GUI

---

**Happy Mining! ⛏️💎**

## Що таке Max Tries та Складність

### Max Tries (Максимальні Спроби)
**Max Tries** - це максимальна кількість спроб знайти правильний nonce (число) для блоку:

1. **Процес майнінгу:**
   - Майнер бере заголовок блоку
   - Пробує різні nonce (0, 1, 2, 3...)
   - Для кожного nonce рахує hash
   - Якщо hash менший за target (складність) - блок знайдено!
   - Якщо після max_tries спроб блок не знайдено - спроба завершується

2. **Приклади:**
   ```bash
   # Поточна складність: 0.001147
   # Потрібно приблизно: ~1,000 спроб для блоку
   
   # Якщо складність стане 1.0
   # Потрібно приблизно: ~1,000,000 спроб
   
   # Якщо складність стане 100
   # Потрібно приблизно: ~100,000,000 спроб
   ```

### Складність та Майбутнє
**Проблема зростання складності:**
- Зараз складність: `0.001147` (супернизька)
- При зростанні складності фіксований max_tries може не вистачати
- Майнінг буде "зависати" - не знаходити блоки

**Рішення - Адаптивний майнінг:**
- Автоматично підлаштовує max_tries під поточну складність
- Формула: `base_tries × difficulty × safety_factor`
- Мінімум: 1,000,000 спроб
- Максимум: 100,000,000 спроб

## Типи Майнінгу

### 1. GUI Майнінг (Standalone)
**Запуск:**
```bash
./src/qt/bitcoin-qt -datadir=/Users/serbinov/.krepto
```

**Особливості:**
- ✅ Повністю standalone (не потребує CLI)
- ✅ Адаптивний max_tries на основі складності
- ✅ Вбудований демон
- ✅ Майнінг одним кліком через Tools → Mining Console
- ✅ Реальний час логування та статистика

### 2. CLI Скрипт (Оригінальний)
**Запуск:**
```bash
./mine_krepto.sh [address] [blocks_per_batch]
```

**Особливості:**
- ✅ Швидкий та ефективний
- ✅ Фіксований max_tries: 10,000,000
- ⚠️ Може не вистачати при високій складності

### 3. Адаптивний Скрипт (Рекомендований)
**Запуск:**
```bash
./mine_krepto_adaptive.sh [address] [blocks_per_batch]
```

**Особливості:**
- ✅ Автоматично підлаштовується під складність
- ✅ Перевіряє складність кожну хвилину
- ✅ Безпечний для майбутнього зростання складності
- ✅ Показує детальну інформацію про адаптацію

**Приклад виводу:**
```
📊 Difficulty Update:
   Height: 4761
   Difficulty: 0.001147
   Adaptive max_tries: 11470

⛏️  Mining attempt #1 - 1 block(s) (max_tries: 11470)...
✅ SUCCESS! Mined 1 block(s)! Height: 4762
```

### 4. GUI RPC Скрипт
**Запуск:**
```bash
./mine_krepto_gui.sh [address] [blocks_per_batch]
```

**Особливості:**
- ✅ Працює паралельно з GUI
- ✅ Використовує ту ж логіку що оригінальний скрипт
- ✅ Підключається через RPC порт 12347

## Рекомендації

### Для Поточного Використання
- **GUI майнінг** - найпростіший для користувачів
- **Адаптивний скрипт** - найнадійніший для довгострокового майнінгу

### Для Майбутнього
При зростанні складності:
1. **Складність 0.001-1.0** - всі методи працюють
2. **Складність 1.0-10** - потрібен адаптивний майнінг
3. **Складність 10+** - обов'язково адаптивний майнінг

### Моніторинг Складності
```bash
# Перевірити поточну складність
./src/bitcoin-cli -datadir=/Users/serbinov/.krepto getblockchaininfo | grep difficulty

# Результат
"difficulty": 0.001147192891552767
```

## Усунення Проблем

### Майнінг "Зависає"
**Симптоми:** Довгі паузи, блоки не знаходяться
**Причина:** Max_tries занадто малий для поточної складності
**Рішення:** Використовуйте адаптивний майнінг

### GUI Майнінг Не Працює
**Симптоми:** Помилки запуску, segmentation fault
**Рішення:**
1. Перевірте, чи не запущений інший процес
2. Перекомпілюйте: `make -j8`
3. Запустіть з чистого терміналу

### Низька Швидкість Майнінгу
**Причини:**
- Занадто великий max_tries для поточної складності
- Конфлікти між паралельними майнерами
**Рішення:** Використовуйте адаптивний майнінг з рандомізацією 