# Krepto Windows Build Instructions

## Огляд

Цей документ містить детальні інструкції для збірки Krepto на Windows. У нас є два автоматизовані скрипти для спрощення процесу.

## Системні вимоги

### Обов'язкові компоненти:
- **Windows 10 або новіша** (64-bit)
- **Visual Studio 2019 або 2022** (Community, Professional, або Enterprise)
  - Встановіть з компонентами: "Desktop development with C++"
- **Git for Windows**
- **Python 3.7+**

### Рекомендовані ресурси:
- **RAM**: 8GB+ (мінімум 4GB)
- **Диск**: 20GB+ вільного місця
- **CPU**: 4+ ядра для швидшої збірки

## Варіант 1: Автоматична збірка (Рекомендовано)

### Використання PowerShell скрипта (Сучасний підхід):

1. **Відкрийте PowerShell як адміністратор**
2. **Перейдіть до директорії Krepto**:
   ```powershell
   cd C:\path\to\krepto
   ```
3. **Запустіть скрипт**:
   ```powershell
   .\Build-Krepto-Windows.ps1
   ```

### Використання Batch файлу (Класичний підхід):

1. **Відкрийте Command Prompt як адміністратор**
2. **Перейдіть до директорії Krepto**:
   ```cmd
   cd C:\path\to\krepto
   ```
3. **Запустіть скрипт**:
   ```cmd
   build-windows.bat
   ```

## Варіант 2: Ручна збірка

### Крок 1: Встановлення vcpkg

```cmd
git clone https://github.com/Microsoft/vcpkg.git C:\vcpkg
cd C:\vcpkg
.\bootstrap-vcpkg.bat
.\vcpkg.exe integrate install
```

### Крок 2: Встановлення залежностей

```cmd
C:\vcpkg\vcpkg.exe install boost:x64-windows-static
C:\vcpkg\vcpkg.exe install libevent:x64-windows-static
C:\vcpkg\vcpkg.exe install openssl:x64-windows-static
C:\vcpkg\vcpkg.exe install berkeleydb:x64-windows-static
C:\vcpkg\vcpkg.exe install qt5-base:x64-windows-static
C:\vcpkg\vcpkg.exe install qt5-tools:x64-windows-static
C:\vcpkg\vcpkg.exe install qt5-winextras:x64-windows-static
```

### Крок 3: Генерація проєктних файлів

```cmd
cd C:\path\to\krepto
python build_msvc\msvc-autogen.py
```

### Крок 4: Збірка

```cmd
"C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe" build_msvc\bitcoin.sln -property:Configuration=Release -property:Platform=x64 -maxCpuCount
```

## Результат збірки

Після успішної збірки ви отримаєте:

### Файли:
- `Krepto-Windows-Release\` - папка з готовими файлами
- `Krepto-Windows-v1.0.0.zip` - ZIP архів для розповсюдження
- `build-info.txt` - інформація про збірку

### Виконувані файли:
- **krepto-qt.exe** - GUI додаток (основний)
- **kryptod.exe** - Daemon/сервер
- **krepto-cli.exe** - Інтерфейс командного рядка
- **krepto-tx.exe** - Утиліта транзакцій
- **krepto-util.exe** - Загальна утиліта
- **krepto-wallet.exe** - Утиліта гаманця

### Конфігурація:
- **krepto.conf** - Файл конфігурації мережі
- **README.txt** - Інструкції для користувачів
- **Start-Krepto-GUI.bat** - Швидкий запуск GUI

## Мережеві налаштування

Krepto використовує наступні налаштування:
- **Основний порт**: 12345
- **RPC порт**: 12347
- **Seed вузли**: 
  - 164.68.117.90:12345
  - 5.189.133.204:12345

## Усунення проблем

### Проблема: "MSBuild not found"
**Рішення**: Встановіть Visual Studio 2019/2022 з компонентом "Desktop development with C++"

### Проблема: "vcpkg install failed"
**Рішення**: 
1. Запустіть Command Prompt як адміністратор
2. Перевірте інтернет-з'єднання
3. Очистіть кеш vcpkg: `C:\vcpkg\vcpkg.exe remove --outdated`

### Проблема: "Python not found"
**Рішення**: Встановіть Python 3.7+ і додайте до PATH

### Проблема: "Git not found"
**Рішення**: Встановіть Git for Windows

## Тестування збірки

Після збірки протестуйте:

1. **Запустіть GUI**:
   ```cmd
   cd Krepto-Windows-Release
   krepto-qt.exe
   ```

2. **Перевірте CLI**:
   ```cmd
   krepto-cli.exe --version
   ```

3. **Перевірте daemon**:
   ```cmd
   kryptod.exe --version
   ```

## Розповсюдження

Готовий ZIP файл `Krepto-Windows-v1.0.0.zip` містить:
- Усі виконувані файли
- Конфігурацію мережі
- Інструкції для користувачів
- Скрипт швидкого запуску

## Підтримка

Якщо виникають проблеми:
1. Перевірте системні вимоги
2. Переконайтеся, що всі залежності встановлені
3. Запустіть збірку як адміністратор
4. Перевірте логи збірки на помилки

## Додаткові параметри

### PowerShell скрипт підтримує параметри:
```powershell
.\Build-Krepto-Windows.ps1 -Configuration Debug -Platform x64 -VcpkgRoot "D:\vcpkg"
```

### Параметри:
- **Configuration**: Release (за замовчуванням) або Debug
- **Platform**: x64 (за замовчуванням) або x86
- **VcpkgRoot**: Шлях до vcpkg (за замовчуванням C:\vcpkg)

---

**Примітка**: Збірка може зайняти 30-60 хвилин залежно від швидкості системи та інтернет-з'єднання. 