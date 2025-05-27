# Tech Context - Krepto

## Технологічний стек

### Основні технології
- **Мова програмування**: C++17
- **GUI Framework**: Qt 5.15+
- **Система збірки**: Autotools + Make
- **База даних**: LevelDB (блокчейн), Berkeley DB (гаманець)
- **Криптографія**: OpenSSL, libsecp256k1
- **Мережа**: Boost.Asio
- **Тестування**: Boost.Test

### Залежності
```
Required:
- GCC 7+ або Clang 5+
- Qt 5.15+ (для GUI)
- OpenSSL 1.1+
- Boost 1.64+
- libevent 2.1+
- libdb 4.8+ (Berkeley DB)

Optional:
- miniupnpc (UPnP підтримка)
- libqrencode (QR коди)
- protobuf (для платіжних запитів)
- ZeroMQ (для повідомлень)
```

## Структура проєкту

### Основні директорії
```
krepto/
├── src/                 # Основний код
│   ├── kernel/         # Ядро блокчейну
│   ├── qt/             # GUI компоненти
│   ├── wallet/         # Функціональність гаманця
│   ├── rpc/            # RPC інтерфейс
│   ├── consensus/      # Правила консенсусу
│   └── net/            # Мережевий рівень
├── build-aux/          # Допоміжні скрипти збірки
├── depends/            # Система залежностей
├── doc/                # Документація
├── test/               # Тести
└── contrib/            # Допоміжні інструменти
```

### Конфігураційні файли
- `configure.ac` - Autotools конфігурація
- `Makefile.am` - Make файли
- `src/config/bitcoin-config.h.in` - Конфігурація компіляції

## Система збірки

### Autotools Workflow
```bash
# 1. Генерація configure скрипта
./autogen.sh

# 2. Конфігурація збірки
./configure --enable-wallet --with-gui=qt5

# 3. Компіляція
make -j$(nproc)

# 4. Встановлення (опціонально)
make install
```

### Опції конфігурації
```bash
# Основні опції
--enable-wallet          # Включити гаманець
--with-gui=qt5          # GUI з Qt5
--enable-debug          # Debug збірка
--disable-tests         # Вимкнути тести

# Оптимізація
--enable-lto            # Link Time Optimization
--enable-glibc-back-compat  # Сумісність з старими glibc

# Залежності
--with-boost=<path>     # Шлях до Boost
--with-qt-bindir=<path> # Шлях до Qt binaries
```

## Мережеві параметри

### Krepto Network Configuration
```cpp
// chainparams.cpp modifications
class CMainParams : public CChainParams {
public:
    CMainParams() {
        strNetworkID = "main";
        consensus.nSubsidyHalvingInterval = 210000;
        consensus.BIP16Exception = uint256S("0x00");
        consensus.BIP34Height = 0;
        consensus.BIP34Hash = uint256S("0x00");
        consensus.BIP65Height = 0;
        consensus.BIP66Height = 0;
        consensus.CSVHeight = 0;
        consensus.SegwitHeight = 0;
        consensus.MinBIP9WarningHeight = 0;
        consensus.powLimit = uint256S("0x00000fffffffffffffffffffffffffffffffffffffffffffffffffffffffffff");
        consensus.nPowTargetTimespan = 14 * 24 * 60 * 60; // two weeks
        consensus.nPowTargetSpacing = 10 * 60;
        consensus.fPowAllowMinDifficultyBlocks = false;
        consensus.fPowNoRetargeting = false;
        consensus.nRuleChangeActivationThreshold = 1916; // 95% of 2016
        consensus.nMinerConfirmationWindow = 2016;
        
        // Krepto specific parameters
        pchMessageStart[0] = 0x4b; // K
        pchMessageStart[1] = 0x52; // R
        pchMessageStart[2] = 0x45; // E
        pchMessageStart[3] = 0x50; // P
        nDefaultPort = 12345;
        nPruneAfterHeight = 100000;
        
        // Genesis block
        genesis = CreateGenesisBlock(1748270717, 0, 0x207fffff, 1, 50 * COIN);
        consensus.hashGenesisBlock = genesis.GetHash();
        
        // Address prefixes
        base58Prefixes[PUBKEY_ADDRESS] = std::vector<unsigned char>(1,45);  // K
        base58Prefixes[SCRIPT_ADDRESS] = std::vector<unsigned char>(1,50);  // M
        base58Prefixes[SECRET_KEY] = std::vector<unsigned char>(1,173);
        base58Prefixes[EXT_PUBLIC_KEY] = {0x04, 0x88, 0xB2, 0x1E};
        base58Prefixes[EXT_SECRET_KEY] = {0x04, 0x88, 0xAD, 0xE4};
        
        bech32_hrp = "kr";
        
        // Seed nodes (empty for now)
        vSeeds.clear();
        
        // Checkpoints (empty for new chain)
        checkpointData = {
            {}
        };
        
        chainTxData = ChainTxData{
            1748270717, // Genesis time
            0,          // Total transactions
            0           // Transactions per second
        };
    }
};
```

## Розробницьке середовище

### Рекомендовані IDE
- **CLion** - Повна підтримка C++ та CMake
- **VS Code** - З розширеннями C++ та Git
- **Qt Creator** - Для роботи з GUI компонентами

### Налаштування середовища
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install build-essential libtool autotools-dev automake pkg-config bsdmainutils python3
sudo apt-get install libssl-dev libevent-dev libboost-system-dev libboost-filesystem-dev libboost-test-dev libboost-thread-dev
sudo apt-get install qtbase5-dev qttools5-dev-tools
sudo apt-get install libdb++-dev

# macOS (Homebrew)
brew install autoconf automake libtool pkg-config
brew install openssl libevent boost
brew install qt5
brew install berkeley-db4
```

## Тестування

### Типи тестів
1. **Unit Tests** - `src/test/`
2. **Functional Tests** - `test/functional/`
3. **Fuzz Tests** - `test/fuzz/`
4. **Integration Tests** - `test/util/`

### Запуск тестів
```bash
# Unit тести
make check

# Functional тести
test/functional/test_runner.py

# Specific test
test/functional/wallet_basic.py
```

## Налагодження

### Debug збірка
```bash
./configure --enable-debug --disable-optimize-debug
make -j$(nproc)
```

### Корисні інструменти
- **GDB** - Налагодження C++
- **Valgrind** - Пошук витоків пам'яті
- **AddressSanitizer** - Виявлення помилок пам'яті
- **ThreadSanitizer** - Виявлення race conditions

## Безпека

### Компіляційні прапори
```bash
# Hardening flags
CXXFLAGS="-D_FORTIFY_SOURCE=2 -fstack-protector-strong -Wformat -Werror=format-security"
LDFLAGS="-Wl,-z,relro -Wl,-z,now"
```

### Статичний аналіз
- **Clang Static Analyzer**
- **Cppcheck**
- **PVS-Studio**

## Документація

### Генерація документації
```bash
# Doxygen documentation
doxygen doc/Doxyfile

# Man pages
make install-man
```

### Важливі файли документації
- `doc/build-*.md` - Інструкції збірки для різних ОС
- `doc/developer-notes.md` - Нотатки для розробників
- `doc/release-notes/` - Нотатки релізів 