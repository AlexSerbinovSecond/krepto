# System Patterns - Krepto Architecture

## Архітектурний огляд
Krepto базується на архітектурі Krepto core з мінімальними змінами для збереження стабільності та безпеки.

## Ключові компоненти

### Core Components
```
krepto/
├── src/
│   ├── kernel/           # Core blockchain logic
│   │   └── chainparams.cpp  # Network parameters (MODIFIED)
│   ├── qt/              # GUI components (TO BE MODIFIED)
│   ├── rpc/             # RPC interface
│   ├── wallet/          # Wallet functionality
│   ├── consensus/       # Consensus rules
│   └── net/             # Network layer
```

### Модифіковані файли
1. **chainparams.cpp** - Основні мережеві параметри
2. **GUI файли** - Ребрендинг інтерфейсу (планується)
3. **Конфігураційні файли** - Налаштування збірки (планується)

## Патерни проєктування

### 1. Мінімальні зміни (Minimal Fork Pattern)
- **Принцип**: Змінювати тільки необхідне
- **Переваги**: Збереження стабільності, легкість оновлень
- **Застосування**: Тільки мережеві параметри та брендинг

### 2. Конфігураційний підхід (Configuration-Driven)
- **Принцип**: Всі зміни через конфігурацію
- **Переваги**: Централізоване управління параметрами
- **Застосування**: chainparams.cpp як єдине джерело істини

### 3. Збереження API (API Compatibility)
- **Принцип**: Зберігати сумісність з Krepto core API
- **Переваги**: Сумісність з існуючими інструментами
- **Застосування**: RPC інтерфейс залишається незмінним

## Мережева архітектура

### Genesis Block Integration
```cpp
// Genesis block parameters
consensus.hashGenesisBlock = uint256S("5e5d3365087e5962e40030aa9e43231c24f4057ddfbacb069fb19cfc935c23c9");
genesis.hashMerkleRoot = uint256S("5976614bb121054435ae20ef7100ecc07f176b54a7bf908493272d716f8409b4");
genesis.nTime = 1748270717;
genesis.nNonce = 0;
genesis.nBits = 0x207fffff;
```

### Network Parameters
```cpp
// Network identification
pchMessageStart[0] = 0x4b; // K
pchMessageStart[1] = 0x52; // R  
pchMessageStart[2] = 0x45; // E
pchMessageStart[3] = 0x50; // P

// Ports
nDefaultPort = 12345;
nRPCPort = 12346;

// Address prefixes
base58Prefixes[PUBKEY_ADDRESS] = std::vector<unsigned char>(1,45);  // 'K'
base58Prefixes[SCRIPT_ADDRESS] = std::vector<unsigned char>(1,50);  // 'M'
```

## Компонентна взаємодія

### 1. Blockchain Layer
- **Consensus Engine**: Правила валідації блоків
- **Chain State**: Поточний стан блокчейну
- **Block Storage**: Зберігання блоків на диску

### 2. Network Layer
- **P2P Protocol**: Комунікація між нодами
- **Message Handling**: Обробка мережевих повідомлень
- **Peer Management**: Управління з'єднаннями

### 3. Wallet Layer
- **Key Management**: Управління приватними ключами
- **Transaction Building**: Створення транзакцій
- **Address Generation**: Генерація адрес

### 4. RPC Layer
- **JSON-RPC Server**: API для зовнішніх додатків
- **Command Processing**: Обробка RPC команд
- **Response Formatting**: Форматування відповідей

## Безпека та валідація

### Consensus Rules
- Використання Bitcoin consensus rules
- Валідація блоків та транзакцій
- Перевірка proof-of-work

### Network Security
- Криптографічна перевірка повідомлень
- Захист від атак на мережу
- Валідація peer connections

## Патерни розширення

### 1. Plugin Architecture
- Модульна структура для майбутніх розширень
- Інтерфейси для додавання нової функціональності

### 2. Configuration Management
- Централізоване управління налаштуваннями
- Підтримка різних мережевих конфігурацій

### 3. Event System
- Система подій для моніторингу
- Hooks для інтеграції з зовнішніми системами

## Технічні обмеження

### Збереження сумісності
- Не змінювати основні алгоритми
- Зберігати структуру даних
- Підтримувати існуючі інтерфейси

### Продуктивність
- Мінімальний вплив на швидкість
- Ефективне використання пам'яті
- Оптимізація мережевого трафіку 