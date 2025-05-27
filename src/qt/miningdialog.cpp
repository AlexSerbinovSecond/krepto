#include <qt/miningdialog.h>
#include <qt/clientmodel.h>
#include <qt/walletmodel.h>
#include <qt/guiutil.h>
#include <key_io.h>
#include <wallet/wallet.h>
#include <outputtype.h>

#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QTextEdit>
#include <QProgressBar>
#include <QLabel>
#include <QPushButton>
#include <QTimer>
#include <QDateTime>
#include <QScrollBar>
#include <QFont>
#include <QGroupBox>
#include <QGridLayout>
#include <QMessageBox>
#include <QProcess>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QJsonParseError>
#include <random>
#include <chrono>

MiningDialog::MiningDialog(QWidget *parent) :
    QDialog(parent),
    clientModel(nullptr),
    walletModel(nullptr),
    isMining(false),
    blocksFound(0),
    totalAttempts(0),
    currentHashRate(0.0),
    blockHeight(1),
    currentNonce(0),
    hashCount(0)
{
    setWindowTitle(tr("Krepto Mining Console"));
    setMinimumSize(800, 600);
    
    setupUI();
    
    // Setup update timer
    updateTimer = new QTimer(this);
    connect(updateTimer, &QTimer::timeout, this, &MiningDialog::updateDisplay);
    updateTimer->start(1000); // Update every second
}

MiningDialog::~MiningDialog()
{
    if (isMining) {
        stopMining();
    }
}

void MiningDialog::setupUI()
{
    QVBoxLayout *mainLayout = new QVBoxLayout(this);
    
    // Status group
    QGroupBox *statusGroup = new QGroupBox(tr("Mining Status"));
    QGridLayout *statusLayout = new QGridLayout(statusGroup);
    
    statusLabel = new QLabel(tr("Status: Stopped"));
    statusLabel->setStyleSheet("QLabel { color: red; font-weight: bold; }");
    statusLayout->addWidget(new QLabel(tr("Status:")), 0, 0);
    statusLayout->addWidget(statusLabel, 0, 1);
    
    hashRateLabel = new QLabel(tr("0 H/s"));
    hashRateLabel->setStyleSheet("QLabel { color: blue; font-weight: bold; }");
    statusLayout->addWidget(new QLabel(tr("Hash Rate:")), 1, 0);
    statusLayout->addWidget(hashRateLabel, 1, 1);
    
    blocksFoundLabel = new QLabel(tr("Blocks Found: 0"));
    statusLayout->addWidget(new QLabel(tr("Progress:")), 2, 0);
    statusLayout->addWidget(blocksFoundLabel, 2, 1);
    
    progressBar = new QProgressBar();
    progressBar->setRange(0, 100);
    progressBar->setValue(0);
    statusLayout->addWidget(progressBar, 3, 0, 1, 2);
    
    mainLayout->addWidget(statusGroup);
    
    // Control buttons
    QHBoxLayout *buttonLayout = new QHBoxLayout();
    
    startButton = new QPushButton(tr("Start Mining"));
    startButton->setStyleSheet("QPushButton { background-color: green; color: white; font-weight: bold; }");
    connect(startButton, &QPushButton::clicked, this, &MiningDialog::startMining);
    buttonLayout->addWidget(startButton);
    
    stopButton = new QPushButton(tr("Stop Mining"));
    stopButton->setStyleSheet("QPushButton { background-color: red; color: white; font-weight: bold; }");
    stopButton->setEnabled(false);
    connect(stopButton, &QPushButton::clicked, this, &MiningDialog::stopMining);
    buttonLayout->addWidget(stopButton);
    
    clearLogButton = new QPushButton(tr("Clear Log"));
    connect(clearLogButton, &QPushButton::clicked, [this]() {
        logTextEdit->clear();
        logMessage(tr("Log cleared"));
    });
    buttonLayout->addWidget(clearLogButton);
    
    buttonLayout->addStretch();
    mainLayout->addLayout(buttonLayout);
    
    // Mining log
    QGroupBox *logGroup = new QGroupBox(tr("Mining Log"));
    QVBoxLayout *logLayout = new QVBoxLayout(logGroup);
    
    logTextEdit = new QTextEdit();
    logTextEdit->setReadOnly(true);
    logTextEdit->setFont(QFont("Courier", 9));
    logTextEdit->setStyleSheet("QTextEdit { background-color: black; color: green; }");
    logLayout->addWidget(logTextEdit);
    
    mainLayout->addWidget(logGroup);
    
    // Initial log message
    logMessage(tr("Mining console initialized. Ready to start mining."));
    logMessage(tr("Note: This will show real-time hash calculations and nonce attempts."));
}

void MiningDialog::setClientModel(ClientModel *model)
{
    this->clientModel = model;
}

void MiningDialog::setWalletModel(WalletModel *model)
{
    this->walletModel = model;
}

void MiningDialog::startMining()
{
    if (!walletModel) {
        QMessageBox::warning(this, tr("Mining Error"), 
                           tr("No wallet available. Please create or open a wallet first."));
        return;
    }
    
    if (isMining) {
        return;
    }
    
    isMining = true;
    blocksFound = 0;
    totalAttempts = 0;
    
    startButton->setEnabled(false);
    stopButton->setEnabled(true);
    
    statusLabel->setText(tr("Status: Mining"));
    statusLabel->setStyleSheet("QLabel { color: green; font-weight: bold; }");
    
    // Emit signal to update main GUI
    Q_EMIT miningStarted();
    
    logMessage(tr("=== MINING STARTED ==="));
    logMessage(tr("Initializing mining process..."));
    logMessage(tr("Getting mining address from wallet..."));
    
    // Get or create mining address
    try {
        QString miningAddress;
        
        // First, try to get existing receiving address
        auto addresses = walletModel->wallet().getAddresses();
        for (const auto& addr : addresses) {
            if (addr.purpose == wallet::AddressPurpose::RECEIVE) {
                miningAddress = QString::fromStdString(EncodeDestination(addr.dest));
                logMessage(tr("Found existing address: %1").arg(miningAddress));
                break;
            }
        }
        
        // If no existing address found, create a new one
        if (miningAddress.isEmpty()) {
            logMessage(tr("No existing addresses found. Creating new mining address..."));
            auto new_addr = walletModel->wallet().getNewDestination(OutputType::LEGACY, "mining");
            if (new_addr) {
                miningAddress = QString::fromStdString(EncodeDestination(*new_addr));
                logMessage(tr("Created new legacy address: %1").arg(miningAddress));
            } else {
                logMessage(tr("ERROR: Failed to create new mining address"));
                stopMining();
                return;
            }
        }
        
        if (miningAddress.isEmpty()) {
            logMessage(tr("ERROR: Unable to get or create mining address!"));
            stopMining();
            return;
        }
        
        logMessage(tr("Mining to address: %1").arg(miningAddress));
        logMessage(tr("Starting hash calculations..."));
        logMessage(tr(""));
        
        // Start the actual mining process
        simulateMining();
        
    } catch (const std::exception& e) {
        logMessage(tr("ERROR: Failed to get/create mining address: %1").arg(QString::fromStdString(e.what())));
        stopMining();
    }
}

void MiningDialog::stopMining()
{
    if (!isMining) {
        return;
    }
    
    isMining = false;
    
    startButton->setEnabled(true);
    stopButton->setEnabled(false);
    
    statusLabel->setText(tr("Status: Stopped"));
    statusLabel->setStyleSheet("QLabel { color: red; font-weight: bold; }");
    
    currentHashRate = 0.0;
    hashRateLabel->setText(tr("0 H/s"));
    
    // Emit signal to update main GUI
    Q_EMIT miningStopped();
    
    logMessage(tr(""));
    logMessage(tr("=== MINING STOPPED ==="));
    logMessage(tr("Total attempts: %1").arg(totalAttempts));
    logMessage(tr("Blocks found: %1").arg(blocksFound));
}

void MiningDialog::simulateMining()
{
    // Real mining using RPC generatetoaddress command
    logMessage(tr("Starting mining process..."));
    
    QTimer *miningTimer = new QTimer(this);
    connect(miningTimer, &QTimer::timeout, [this, miningTimer]() {
        if (!isMining) {
            miningTimer->stop();
            miningTimer->deleteLater();
            return;
        }
        
        // Always generate a fresh legacy address for mining to avoid witness issues
        QString miningAddress;
        if (walletModel) {
            try {
                logMessage(tr("Generating fresh legacy address for mining..."));
                auto new_addr = walletModel->wallet().getNewDestination(OutputType::LEGACY, "mining");
                if (new_addr) {
                    miningAddress = QString::fromStdString(EncodeDestination(*new_addr));
                    logMessage(tr("Generated legacy address for mining: %1").arg(miningAddress));
                } else {
                    logMessage(tr("ERROR: Failed to generate legacy address"));
                    stopMining();
                    return;
                }
            } catch (const std::exception& e) {
                logMessage(tr("ERROR: Failed to generate mining address: %1").arg(QString::fromStdString(e.what())));
                stopMining();
                return;
            }
        }
        
        if (miningAddress.isEmpty()) {
            logMessage(tr("ERROR: No mining address available"));
            stopMining();
            return;
        }
        
        // Execute real mining command via RPC with randomization
        logMessage(tr("⛏️  Attempting to mine 1 block to address: %1").arg(miningAddress));
        
        // Add randomization to prevent parallel mining conflicts
        // Generate random max_tries between 500,000 and 2,000,000
        static std::random_device rd;
        static std::mt19937 gen(rd());
        std::uniform_int_distribution<> tries_dist(500000, 2000000);
        int randomMaxTries = tries_dist(gen);
        
        // Add random delay between 0-5 seconds to stagger mining attempts
        std::uniform_int_distribution<> delay_dist(0, 5000);
        int randomDelay = delay_dist(gen);
        
        logMessage(tr("🎲 Using randomized parameters: max_tries=%1, delay=%2ms")
                  .arg(randomMaxTries).arg(randomDelay));
        
        // Apply random delay before starting
        QTimer::singleShot(randomDelay, [this, miningAddress, randomMaxTries]() {
            if (!isMining) return;
            
            // Use QProcess to execute bitcoin-cli command
            QProcess *process = new QProcess(this);
            QString program = "./src/bitcoin-cli";
            QStringList arguments;
            arguments << "-datadir=/Users/serbinov/.krepto"
                      << "-rpcport=12347"
                      << "generatetoaddress"
                      << "1"
                      << miningAddress
                      << QString::number(randomMaxTries); // Randomized max tries
        
        connect(process, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
                [this, process, miningAddress, randomMaxTries](int exitCode, QProcess::ExitStatus exitStatus) {
            QString output = process->readAllStandardOutput();
            QString error = process->readAllStandardError();
            
            if (exitCode == 0 && !output.isEmpty()) {
                // Parse JSON output to get block hashes
                QJsonParseError parseError;
                QJsonDocument doc = QJsonDocument::fromJson(output.toUtf8(), &parseError);
                
                if (parseError.error == QJsonParseError::NoError && doc.isArray()) {
                    QJsonArray blocks = doc.array();
                    if (blocks.size() > 0) {
                        blocksFound++;
                        totalAttempts += randomMaxTries; // Use actual randomized attempts
                        
                        QString blockHash = blocks[0].toString();
                        logMessage(tr(""));
                        logMessage(tr("*** BLOCK FOUND! ***"));
                        logMessage(tr("✅ Block %1 mined successfully!").arg(blocksFound));
                        logMessage(tr("🔗 Block hash: %1").arg(blockHash));
                        logMessage(tr("📍 Mined to address: %1").arg(miningAddress));
                        logMessage(tr(""));
                        
                        // Get updated blockchain info
                        getBlockchainInfo();
                    }
                } else {
                    logMessage(tr("⚠️  Mining attempt completed but no block found"));
                }
            } else {
                if (!error.isEmpty()) {
                    logMessage(tr("❌ Mining error: %1").arg(error));
                } else {
                    logMessage(tr("⚠️  Mining attempt failed (exit code: %1)").arg(exitCode));
                }
            }
            
            // Update hash rate (approximate)
            currentHashRate = randomMaxTries; // Use actual randomized attempts
            hashCount++;
            
            process->deleteLater();
        });
        
            process->start(program, arguments);
            
            if (!process->waitForStarted()) {
                logMessage(tr("ERROR: Failed to start mining process"));
                stopMining();
            }
        });
    });
    
    miningTimer->start(10000); // Try mining every 10 seconds
}

void MiningDialog::updateMiningLog(const QString &message)
{
    logMessage(message);
}

void MiningDialog::updateHashRate(double hashRate)
{
    currentHashRate = hashRate;
}

void MiningDialog::updateProgress(int blocks, int attempts)
{
    blocksFound = blocks;
    totalAttempts = attempts;
}

void MiningDialog::syncMiningState(bool mining)
{
    // Update UI state without triggering signals to avoid loops
    isMining = mining;
    startButton->setEnabled(!mining);
    stopButton->setEnabled(mining);
    
    if (mining) {
        statusLabel->setText(tr("Status: Mining"));
        statusLabel->setStyleSheet("QLabel { color: green; font-weight: bold; }");
    } else {
        statusLabel->setText(tr("Status: Stopped"));
        statusLabel->setStyleSheet("QLabel { color: red; font-weight: bold; }");
        currentHashRate = 0.0;
        hashRateLabel->setText(tr("0 H/s"));
    }
}

void MiningDialog::updateDisplay()
{
    if (isMining) {
        hashRateLabel->setText(tr("%1 H/s").arg(QString::number(currentHashRate, 'f', 0)));
        blocksFoundLabel->setText(tr("Blocks Found: %1 | Total Attempts: %2")
                                 .arg(blocksFound)
                                 .arg(totalAttempts));
        
        // Update progress bar based on current nonce progress
        int progress = (totalAttempts % 50000) * 100 / 50000;
        progressBar->setValue(progress);
    }
}

void MiningDialog::logMessage(const QString &message)
{
    QMutexLocker locker(&logMutex);
    
    QString timestamp = QDateTime::currentDateTime().toString("hh:mm:ss");
    QString formattedMessage = QString("[%1] %2").arg(timestamp, message);
    
    logTextEdit->append(formattedMessage);
    
    // Auto-scroll to bottom
    QScrollBar *scrollBar = logTextEdit->verticalScrollBar();
    scrollBar->setValue(scrollBar->maximum());
}

void MiningDialog::getBlockchainInfo()
{
    QProcess *process = new QProcess(this);
    QString program = "./src/bitcoin-cli";
    QStringList arguments;
    arguments << "-datadir=/Users/serbinov/.krepto"
              << "-rpcport=12347"
              << "getblockchaininfo";
    
    connect(process, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            [this, process](int exitCode, QProcess::ExitStatus exitStatus) {
        if (exitCode == 0) {
            QString output = process->readAllStandardOutput();
            QJsonParseError parseError;
            QJsonDocument doc = QJsonDocument::fromJson(output.toUtf8(), &parseError);
            
            if (parseError.error == QJsonParseError::NoError && doc.isObject()) {
                QJsonObject info = doc.object();
                int blocks = info["blocks"].toInt();
                QString bestHash = info["bestblockhash"].toString();
                double difficulty = info["difficulty"].toDouble();
                
                logMessage(tr("📊 Blockchain Info:"));
                logMessage(tr("   Height: %1 blocks").arg(blocks));
                logMessage(tr("   Difficulty: %1").arg(QString::number(difficulty, 'f', 6)));
                logMessage(tr("   Best block: %1").arg(bestHash));
            }
        }
        process->deleteLater();
    });
    
    process->start(program, arguments);
} 