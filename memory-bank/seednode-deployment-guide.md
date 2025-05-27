# Інструкція для Розгортання Krepto Seed Node з Майнінгом

## 📋 ЗАГАЛЬНА ІНФОРМАЦІЯ

**Мета**: Розгорнути Krepto seed ноду з активним майнінгом на VPS сервері  
**Результат**: Розподілений майнінг між локальним комп'ютером та сервером  
**Призначення**: Для іншої LLM моделі, яка буде виконувати розгортання  

## 🎯 ЦІЛІ РОЗГОРТАННЯ

### Основні Функції Seed Node
1. **Seed Node**: Постійна нода для підключення нових користувачів
2. **Mining Node**: Активний майнінг для підтримки мережі
3. **Network Stability**: Забезпечення стабільності мережі Krepto
4. **Load Distribution**: Розподіл майнінгу між різними нодами

### Очікуваний Результат
- Seed нода працює 24/7 на стабільному сервері
- Майнінг відбувається по черзі: сервер → локальний комп'ютер → сервер
- Нові користувачі автоматично підключаються до seed ноди
- Мережа стає децентралізованою та стійкою

## 🖥️ ВИМОГИ ДО СЕРВЕРА

### Мінімальні Характеристики
- **CPU**: 2+ ядра (для майнінгу)
- **RAM**: 4GB+ (рекомендовано 8GB)
- **Storage**: 50GB+ SSD (для блокчейну)
- **Network**: Стабільне з'єднання, статичний IP
- **OS**: Ubuntu 20.04+ або CentOS 8+

### Рекомендовані VPS Провайдери
- **DigitalOcean**: Droplet $20-40/місяць
- **Linode**: VPS $20-40/місяць  
- **Vultr**: Cloud Compute $20-40/місяць
- **AWS EC2**: t3.medium або більше

## 📦 КРОК 1: ПІДГОТОВКА СЕРВЕРА

### 1.1 Оновлення Системи
```bash
# Ubuntu/Debian
sudo apt update && sudo apt upgrade -y
sudo apt install -y build-essential git wget curl

# CentOS/RHEL
sudo yum update -y
sudo yum groupinstall -y "Development Tools"
sudo yum install -y git wget curl
```

### 1.2 Встановлення Залежностей
```bash
# Ubuntu/Debian
sudo apt install -y \
    autoconf automake libtool pkg-config \
    libssl-dev libevent-dev libboost-all-dev \
    libdb++-dev libminiupnpc-dev libzmq3-dev \
    python3 python3-pip

# CentOS/RHEL  
sudo yum install -y \
    autoconf automake libtool pkgconfig \
    openssl-devel libevent-devel boost-devel \
    libdb-cxx-devel miniupnpc-devel zeromq-devel \
    python3 python3-pip
```

### 1.3 Створення Користувача Krepto
```bash
# Створити окремого користувача для безпеки
sudo useradd -m -s /bin/bash krepto
sudo usermod -aG sudo krepto

# Переключитися на користувача krepto
sudo su - krepto
```

## 📥 КРОК 2: ЗАВАНТАЖЕННЯ ТА ЗБІРКА KREPTO

### 2.1 Клонування Репозиторію
```bash
# Перейти в домашню директорію
cd /home/krepto

# Клонувати Krepto (замінити на актуальний репозиторій)
git clone https://github.com/YOUR_USERNAME/krepto.git
cd krepto
```

### 2.2 Збірка Krepto
```bash
# Налаштування збірки
./autogen.sh
./configure --disable-wallet --disable-gui --enable-daemon

# Компіляція (може зайняти 30-60 хвилин)
make -j$(nproc)

# Перевірка збірки
ls -la src/bitcoind src/bitcoin-cli
```

### 2.3 Встановлення Бінарних Файлів
```bash
# Створити директорії
sudo mkdir -p /usr/local/bin
sudo mkdir -p /home/krepto/.krepto

# Скопіювати бінарні файли
sudo cp src/bitcoind /usr/local/bin/kryptod
sudo cp src/bitcoin-cli /usr/local/bin/krypto-cli
sudo chmod +x /usr/local/bin/kryptod /usr/local/bin/krypto-cli

# Створити симлінки для сумісності
sudo ln -sf /usr/local/bin/kryptod /usr/local/bin/bitcoind
sudo ln -sf /usr/local/bin/krypto-cli /usr/local/bin/bitcoin-cli
```

## ⚙️ КРОК 3: КОНФІГУРАЦІЯ KREPTO NODE

### 3.1 Створення Конфігураційного Файлу
```bash
# Створити конфігураційний файл
cat > /home/krepto/.krepto/bitcoin.conf << 'EOF'
# Krepto Seed Node Configuration

# Network Settings
port=12345
rpcport=12347
rpcbind=0.0.0.0
rpcallowip=0.0.0.0/0

# RPC Authentication
rpcuser=kryptorpc
rpcpassword=GENERATE_STRONG_PASSWORD_HERE

# Node Settings
daemon=1
server=1
listen=1
discover=1

# Mining Settings (ВАЖЛИВО!)
gen=1
genproclimit=2

# Logging
debug=1
logips=1

# Network Limits
maxconnections=125
maxuploadtarget=5000

# Memory Pool
maxmempool=300
mempoolexpiry=72

# Database
dbcache=512
maxorphantx=100

# Seed Node Specific
addnode=127.0.0.1:12345
EOF
```

### 3.2 Генерація Безпечного Паролю
```bash
# Генерувати сильний пароль для RPC
RPC_PASSWORD=$(openssl rand -base64 32)
echo "Generated RPC Password: $RPC_PASSWORD"

# Замінити пароль в конфігурації
sed -i "s/GENERATE_STRONG_PASSWORD_HERE/$RPC_PASSWORD/" /home/krepto/.krepto/bitcoin.conf

# Зберегти пароль для майбутнього використання
echo "RPC_PASSWORD=$RPC_PASSWORD" > /home/krepto/.krepto/rpc_credentials
chmod 600 /home/krepto/.krepto/rpc_credentials
```

### 3.3 Налаштування Firewall
```bash
# Ubuntu/Debian (ufw)
sudo ufw allow 12345/tcp comment "Krepto P2P"
sudo ufw allow 12347/tcp comment "Krepto RPC"
sudo ufw enable

# CentOS/RHEL (firewalld)
sudo firewall-cmd --permanent --add-port=12345/tcp
sudo firewall-cmd --permanent --add-port=12347/tcp
sudo firewall-cmd --reload
```

## 🚀 КРОК 4: ЗАПУСК KREPTO NODE

### 4.1 Створення Systemd Service
```bash
# Створити systemd service файл
sudo cat > /etc/systemd/system/krepto.service << 'EOF'
[Unit]
Description=Krepto Daemon
After=network.target

[Service]
Type=forking
User=krepto
Group=krepto
WorkingDirectory=/home/krepto
ExecStart=/usr/local/bin/kryptod -datadir=/home/krepto/.krepto -daemon
ExecStop=/usr/local/bin/krypto-cli -datadir=/home/krepto/.krepto stop
Restart=always
RestartSec=10
TimeoutStopSec=60
KillMode=process

# Security Settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=full
ProtectHome=false

[Install]
WantedBy=multi-user.target
EOF
```

### 4.2 Запуск та Активація Service
```bash
# Перезавантажити systemd
sudo systemctl daemon-reload

# Активувати автозапуск
sudo systemctl enable krepto

# Запустити Krepto
sudo systemctl start krepto

# Перевірити статус
sudo systemctl status krepto
```

### 4.3 Перевірка Запуску
```bash
# Перевірити логи
sudo journalctl -u krepto -f

# Перевірити RPC з'єднання
bitcoin-cli -datadir=/home/krepto/.krepto getblockchaininfo

# Перевірити майнінг
bitcoin-cli -datadir=/home/krepto/.krepto getmininginfo
```

## ⛏️ КРОК 5: НАЛАШТУВАННЯ МАЙНІНГУ

### 5.1 Створення Майнінг Адреси
```bash
# Створити новий гаманець (якщо потрібно)
bitcoin-cli -datadir=/home/krepto/.krepto createwallet "mining_wallet"

# Створити адресу для майнінгу
MINING_ADDRESS=$(bitcoin-cli -datadir=/home/krepto/.krepto getnewaddress "mining" "legacy")
echo "Mining Address: $MINING_ADDRESS"

# Зберегти адресу
echo "MINING_ADDRESS=$MINING_ADDRESS" >> /home/krepto/.krepto/rpc_credentials
```

### 5.2 Створення Майнінг Скрипта
```bash
# Створити скрипт для автоматичного майнінгу
cat > /home/krepto/mining_script.sh << 'EOF'
#!/bin/bash

# Krepto Mining Script for Seed Node
DATADIR="/home/krepto/.krepto"
LOGFILE="/home/krepto/mining.log"

# Завантажити змінні
source $DATADIR/rpc_credentials

# Функція логування
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a $LOGFILE
}

# Основний цикл майнінгу
while true; do
    # Перевірити чи працює нода
    if ! bitcoin-cli -datadir=$DATADIR getblockchaininfo > /dev/null 2>&1; then
        log_message "ERROR: Krepto node is not running"
        sleep 60
        continue
    fi
    
    # Отримати поточну інформацію
    BLOCKS=$(bitcoin-cli -datadir=$DATADIR getblockcount)
    DIFFICULTY=$(bitcoin-cli -datadir=$DATADIR getdifficulty)
    
    log_message "Current blocks: $BLOCKS, Difficulty: $DIFFICULTY"
    
    # Спробувати майнінг з рандомізацією
    RANDOM_TRIES=$((500000 + RANDOM % 1500000))  # 500K-2M спроб
    RANDOM_DELAY=$((RANDOM % 30 + 10))           # 10-40 секунд затримка
    
    log_message "Starting mining: $RANDOM_TRIES tries, ${RANDOM_DELAY}s delay"
    sleep $RANDOM_DELAY
    
    # Виконати майнінг
    RESULT=$(bitcoin-cli -datadir=$DATADIR generatetoaddress 1 $MINING_ADDRESS $RANDOM_TRIES 2>&1)
    
    if [[ $RESULT == *"["* ]]; then
        BLOCK_HASH=$(echo $RESULT | jq -r '.[0]' 2>/dev/null)
        log_message "SUCCESS: Block mined! Hash: $BLOCK_HASH"
        
        # Отримати оновлену інформацію
        NEW_BLOCKS=$(bitcoin-cli -datadir=$DATADIR getblockcount)
        log_message "New block count: $NEW_BLOCKS"
    else
        log_message "Mining attempt completed, no block found"
    fi
    
    # Пауза між спробами
    sleep 30
done
EOF

# Зробити скрипт виконуваним
chmod +x /home/krepto/mining_script.sh
```

### 5.3 Створення Mining Service
```bash
# Створити systemd service для майнінгу
sudo cat > /etc/systemd/system/krepto-mining.service << 'EOF'
[Unit]
Description=Krepto Mining Service
After=krepto.service
Requires=krepto.service

[Service]
Type=simple
User=krepto
Group=krepto
WorkingDirectory=/home/krepto
ExecStart=/home/krepto/mining_script.sh
Restart=always
RestartSec=30

# Security Settings
NoNewPrivileges=true
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

# Активувати майнінг service
sudo systemctl daemon-reload
sudo systemctl enable krepto-mining
sudo systemctl start krepto-mining

# Перевірити статус майнінгу
sudo systemctl status krepto-mining
```

## 🌐 КРОК 6: ІНТЕГРАЦІЯ З МЕРЕЖЕЮ

### 6.1 Отримання IP Адреси Сервера
```bash
# Отримати зовнішню IP адресу
SERVER_IP=$(curl -s ifconfig.me)
echo "Server IP: $SERVER_IP"

# Зберегти IP для конфігурації
echo "SERVER_IP=$SERVER_IP" >> /home/krepto/.krepto/rpc_credentials
```

### 6.2 Інформація для Оновлення chainparams.cpp
```bash
# Вивести інформацію для додавання в код
cat << EOF

=== ІНФОРМАЦІЯ ДЛЯ ОНОВЛЕННЯ CHAINPARAMS.CPP ===

Додати в src/kernel/chainparams.cpp в секцію CMainParams():

// Krepto seed nodes
vSeeds.emplace_back("$SERVER_IP:12345");

Або якщо є домен:
vSeeds.emplace_back("seed.krepto.org:12345");

=== КОМАНДИ ДЛЯ ТЕСТУВАННЯ З ЛОКАЛЬНОГО КОМП'ЮТЕРА ===

# Підключитися до seed ноди
./src/bitcoin-cli -datadir=/Users/serbinov/.krepto addnode "$SERVER_IP:12345" "add"

# Перевірити підключення
./src/bitcoin-cli -datadir=/Users/serbinov/.krepto getpeerinfo

EOF
```

## 📊 КРОК 7: МОНІТОРИНГ ТА ЛОГУВАННЯ

### 7.1 Створення Моніторинг Скрипта
```bash
# Створити скрипт моніторингу
cat > /home/krepto/monitor.sh << 'EOF'
#!/bin/bash

DATADIR="/home/krepto/.krepto"

echo "=== KREPTO SEED NODE STATUS ==="
echo "Date: $(date)"
echo

# Статус сервісів
echo "--- Services Status ---"
systemctl is-active krepto
systemctl is-active krepto-mining
echo

# Blockchain інформація
echo "--- Blockchain Info ---"
bitcoin-cli -datadir=$DATADIR getblockchaininfo | jq '{blocks, difficulty, chain, verificationprogress}'
echo

# Mining інформація
echo "--- Mining Info ---"
bitcoin-cli -datadir=$DATADIR getmininginfo | jq '{blocks, difficulty, networkhashps, pooledtx}'
echo

# Peer інформація
echo "--- Network Peers ---"
PEER_COUNT=$(bitcoin-cli -datadir=$DATADIR getconnectioncount)
echo "Connected peers: $PEER_COUNT"
echo

# Останні блоки
echo "--- Recent Blocks ---"
bitcoin-cli -datadir=$DATADIR getbestblockhash | xargs bitcoin-cli -datadir=$DATADIR getblock | jq '{height, hash, time, tx: (.tx | length)}'
echo

# Використання ресурсів
echo "--- System Resources ---"
echo "CPU Usage: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)%"
echo "Memory Usage: $(free | grep Mem | awk '{printf "%.1f%%", $3/$2 * 100.0}')"
echo "Disk Usage: $(df -h /home/krepto | awk 'NR==2{print $5}')"
echo
EOF

chmod +x /home/krepto/monitor.sh
```

### 7.2 Налаштування Cron для Моніторингу
```bash
# Додати cron job для регулярного моніторингу
(crontab -l 2>/dev/null; echo "*/10 * * * * /home/krepto/monitor.sh >> /home/krepto/monitor.log 2>&1") | crontab -

# Створити ротацію логів
cat > /home/krepto/logrotate.conf << 'EOF'
/home/krepto/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    copytruncate
}
EOF
```

## 🔧 КРОК 8: НАЛАШТУВАННЯ БЕЗПЕКИ

### 8.1 SSH Безпека
```bash
# Змінити SSH порт (опціонально)
sudo sed -i 's/#Port 22/Port 2222/' /etc/ssh/sshd_config

# Заборонити root login
sudo sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config

# Перезапустити SSH
sudo systemctl restart sshd
```

### 8.2 Fail2Ban для Захисту
```bash
# Встановити fail2ban
sudo apt install -y fail2ban  # Ubuntu/Debian
# sudo yum install -y fail2ban  # CentOS/RHEL

# Створити конфігурацію для Krepto
sudo cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
EOF

# Запустити fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

## ✅ КРОК 9: ПЕРЕВІРКА ТА ТЕСТУВАННЯ

### 9.1 Фінальна Перевірка
```bash
# Перевірити всі сервіси
echo "=== FINAL VERIFICATION ==="

# 1. Krepto daemon
if systemctl is-active --quiet krepto; then
    echo "✅ Krepto daemon: RUNNING"
else
    echo "❌ Krepto daemon: FAILED"
fi

# 2. Mining service
if systemctl is-active --quiet krepto-mining; then
    echo "✅ Mining service: RUNNING"
else
    echo "❌ Mining service: FAILED"
fi

# 3. RPC connection
if bitcoin-cli -datadir=/home/krepto/.krepto getblockchaininfo > /dev/null 2>&1; then
    echo "✅ RPC connection: OK"
else
    echo "❌ RPC connection: FAILED"
fi

# 4. Network ports
if netstat -ln | grep -q ":12345"; then
    echo "✅ P2P port 12345: LISTENING"
else
    echo "❌ P2P port 12345: NOT LISTENING"
fi

if netstat -ln | grep -q ":12347"; then
    echo "✅ RPC port 12347: LISTENING"
else
    echo "❌ RPC port 12347: NOT LISTENING"
fi

# 5. Mining status
MINING_INFO=$(bitcoin-cli -datadir=/home/krepto/.krepto getmininginfo 2>/dev/null)
if [[ $? -eq 0 ]]; then
    echo "✅ Mining info: ACCESSIBLE"
    echo "   Blocks: $(echo $MINING_INFO | jq -r '.blocks')"
    echo "   Difficulty: $(echo $MINING_INFO | jq -r '.difficulty')"
else
    echo "❌ Mining info: FAILED"
fi
```

### 9.2 Тестування з Локального Комп'ютера
```bash
# Команди для виконання на локальному комп'ютері
echo "=== COMMANDS FOR LOCAL COMPUTER ==="
echo
echo "# Підключитися до seed ноди:"
echo "./src/bitcoin-cli -datadir=/Users/serbinov/.krepto addnode \"$SERVER_IP:12345\" \"add\""
echo
echo "# Перевірити підключення:"
echo "./src/bitcoin-cli -datadir=/Users/serbinov/.krepto getpeerinfo"
echo
echo "# Перевірити синхронізацію блоків:"
echo "./src/bitcoin-cli -datadir=/Users/serbinov/.krepto getblockchaininfo"
echo
```

## 📝 КРОК 10: ДОКУМЕНТАЦІЯ ТА ЗБЕРЕЖЕННЯ

### 10.1 Створення README для Сервера
```bash
cat > /home/krepto/README.md << 'EOF'
# Krepto Seed Node

## Server Information
- **Purpose**: Krepto Seed Node with Mining
- **Services**: kryptod, krepto-mining
- **Ports**: 12345 (P2P), 12347 (RPC)
- **Data Directory**: /home/krepto/.krepto

## Important Files
- **Config**: /home/krepto/.krepto/bitcoin.conf
- **Credentials**: /home/krepto/.krepto/rpc_credentials
- **Mining Script**: /home/krepto/mining_script.sh
- **Monitor Script**: /home/krepto/monitor.sh

## Useful Commands
```bash
# Check status
sudo systemctl status krepto krepto-mining

# View logs
sudo journalctl -u krepto -f
sudo journalctl -u krepto-mining -f

# Monitor mining
tail -f /home/krepto/mining.log

# Check blockchain
bitcoin-cli -datadir=/home/krepto/.krepto getblockchaininfo

# Check mining
bitcoin-cli -datadir=/home/krepto/.krepto getmininginfo
```

## Maintenance
- **Logs**: Rotated daily, kept for 7 days
- **Monitoring**: Every 10 minutes via cron
- **Backups**: Manual backup of .krepto directory recommended

## Security
- **Firewall**: Only ports 12345, 12347 open
- **User**: Dedicated 'krepto' user
- **SSH**: Secured with fail2ban
EOF
```

### 10.2 Збереження Важливої Інформації
```bash
# Створити файл з важливою інформацією
cat > /home/krepto/IMPORTANT_INFO.txt << EOF
=== KREPTO SEED NODE DEPLOYMENT INFO ===

Server IP: $SERVER_IP
RPC Password: $RPC_PASSWORD
Mining Address: $MINING_ADDRESS

=== FOR CHAINPARAMS.CPP UPDATE ===
Add to src/kernel/chainparams.cpp:
vSeeds.emplace_back("$SERVER_IP:12345");

=== FOR LOCAL CONNECTION ===
./src/bitcoin-cli addnode "$SERVER_IP:12345" "add"

=== SERVICE COMMANDS ===
sudo systemctl start/stop/restart krepto
sudo systemctl start/stop/restart krepto-mining

=== MONITORING ===
/home/krepto/monitor.sh
tail -f /home/krepto/mining.log

Deployment completed: $(date)
EOF

# Зробити файл доступним тільки для krepto користувача
chmod 600 /home/krepto/IMPORTANT_INFO.txt
```

## 🎉 ЗАВЕРШЕННЯ

### Що Було Розгорнуто
1. ✅ **Krepto Seed Node**: Постійна нода для підключення користувачів
2. ✅ **Mining Service**: Автоматичний майнінг з рандомізацією
3. ✅ **Network Integration**: Готовність до додавання в chainparams.cpp
4. ✅ **Monitoring**: Автоматичний моніторинг та логування
5. ✅ **Security**: Базові заходи безпеки

### Наступні Кроки
1. **Оновити chainparams.cpp** на локальному комп'ютері
2. **Протестувати підключення** між локальним комп'ютером та сервером
3. **Перевірити розподілений майнінг** (блоки по черзі)
4. **Моніторити стабільність** протягом 24-48 годин

### Очікуваний Результат
- Seed нода працює 24/7
- Майнінг відбувається автоматично з рандомізацією
- Нові користувачі можуть підключатися до мережі
- Блоки майняться по черзі між сервером та локальним комп'ютером

**SEED NODE ГОТОВА ДО РОБОТИ!** 🚀 