# Krepto - Команди та Скрипти

## 📋 Основні команди

### Запуск GUI
```bash
# Основна команда (з mainnet даними)
./src/qt/bitcoin-qt -datadir="/Users/serbinov/.krepto"

# Тестовий режим (з тимчасовими даними)
./src/qt/bitcoin-qt -testnet -datadir="/tmp/krepto-test"

# Запуск у фоновому режимі
./src/qt/bitcoin-qt -datadir="/Users/serbinov/.krepto" &
```

### Запуск демона
```bash
# Запуск демона
./src/bitcoind -datadir="/Users/serbinov/.krepto" -daemon

# Зупинка демона
./src/bitcoin-cli -datadir="/Users/serbinov/.krepto" stop
```

### Перевірка стану
```bash
# Перевірка кількості блоків
./src/bitcoin-cli -datadir="/Users/serbinov/.krepto" getblockcount

# Перевірка запущених процесів
ps aux | grep -E "(bitcoind|bitcoin-qt|mine_)" | grep -v grep
```

### Зупинка процесів
```bash
# Зупинка всіх процесів Krepto
pkill -f bitcoind
pkill -f bitcoin-qt
pkill -f mine_

# Або примусово
kill -9 $(pgrep -f "bitcoind|bitcoin-qt|mine_")
```

## 🔨 Збірка проекту

### Повна збірка
```bash
./autogen.sh
./configure --disable-tests --disable-bench --with-gui=qt5
make -j8
```

### Швидка збірка тільки GUI
```bash
make -j8 src/qt/bitcoin-qt
```

### Очистка та перезбірка
```bash
make clean
./autogen.sh
./configure --disable-tests --disable-bench --with-gui=qt5
make -j8
```

## ⛏️ Майнінг

### Запуск майнінгу
```bash
# Запуск скрипта майнінгу до retarget
nohup ./scripts/mine_to_retarget.sh > mining.log 2>&1 &

# Перевірка логів майнінгу
tail -f mining.log
```

### Ручний майнінг
```bash
# Майнінг одного блоку
./src/bitcoin-cli -datadir="/Users/serbinov/.krepto" generatetoaddress 1 $(./src/bitcoin-cli -datadir="/Users/serbinov/.krepto" getnewaddress)
```

## 📁 Скрипти

### Доступні скрипти в папці `scripts/`:

1. **`start_gui.sh`** - Зупиняє процеси та запускає GUI
2. **`rebuild_and_start.sh`** - Зупиняє процеси, перезбирає проект та запускає GUI
3. **`stop_all.sh`** - Зупиняє всі процеси Krepto
4. **`quick_test_gui.sh`** - Швидкий тест GUI (оновлена версія)

### Використання скриптів:
```bash
# Запуск GUI
./scripts/start_gui.sh

# Перезбірка та запуск
./scripts/rebuild_and_start.sh

# Зупинка всіх процесів
./scripts/stop_all.sh

# Швидкий тест GUI
./scripts/quick_test_gui.sh
```

## 🚨 Вирішення проблем

### Помилка "Cannot obtain a lock"
```bash
# Зупинити всі процеси
./scripts/stop_all.sh

# Або вручну
./src/bitcoin-cli -datadir="/Users/serbinov/.krepto" stop
pkill -f bitcoind
pkill -f bitcoin-qt
```

### Проблеми з майнінгом
```bash
# Перевірити статус демона
./src/bitcoin-cli -datadir="/Users/serbinov/.krepto" getblockchaininfo

# Перевірити підключення
./src/bitcoin-cli -datadir="/Users/serbinov/.krepto" getconnectioncount
```

### Проблеми зі збіркою
```bash
# Очистити та перезібрати
make clean
./autogen.sh
./configure --disable-tests --disable-bench --with-gui=qt5
make -j8
```

## 📝 Примітки

- Всі команди виконуються з кореневої директорії проекту `/Users/serbinov/Desktop/projects/upwork/krepto`
- Для швидкого тестування GUI використовуйте тестовий режим
- При зміні GUI коду використовуйте `rebuild_and_start.sh` для швидкої перезбірки
- Логи майнінгу зберігаються в файлі `mining.log` 