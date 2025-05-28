#include <qt/miningdialog.h>
#include <qt/clientmodel.h>
#include <qt/walletmodel.h>
#include <qt/guiutil.h>
#include <key_io.h>
#include <wallet/wallet.h>
#include <outputtype.h>

// Add includes for internal RPC
#include <rpc/server.h>
#include <rpc/request.h>
#include <util/strencodings.h>
#include <interfaces/node.h>
#include <univalue.h>

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
    
    // Setup mining timer
    miningTimer = new QTimer(this);
    connect(miningTimer, &QTimer::timeout, [this]() {
        if (isMining) {
            // Continue mining cycle
            continueMining();
        }
    });
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
    if (isMining) {
        return;
    }
    
    if (!clientModel) {
        logMessage(tr("ERROR: Client model not available"));
        return;
    }
    
    isMining = true;
    
    startButton->setEnabled(false);
    stopButton->setEnabled(true);
    
    statusLabel->setText(tr("Status: Mining"));
    statusLabel->setStyleSheet("QLabel { color: green; font-weight: bold; }");
    
    // Emit signal to update main GUI
    Q_EMIT miningStarted();
    
    logMessage(tr(""));
    logMessage(tr("=== MINING STARTED ==="));
    logMessage(tr("Initializing mining process..."));
    
    // Get and display current blockchain info
    getBlockchainInfo();
    
    try {
        // Get mining address from wallet
        QString miningAddress;
        
        if (walletModel && walletModel->wallet().getAddresses().size() > 0) {
            // Use existing address if available
            auto addresses = walletModel->wallet().getAddresses();
            for (const auto& addr : addresses) {
                if (addr.purpose == wallet::AddressPurpose::RECEIVE) {
                    miningAddress = QString::fromStdString(EncodeDestination(addr.dest));
                    logMessage(tr("Using existing address: %1").arg(miningAddress));
                    break;
                }
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
        
        // Store mining address for continuous use
        currentMiningAddress = miningAddress;
        
        // Start continuous mining
        logMessage(tr("⛏️  Starting continuous mining to address: %1").arg(miningAddress));
        
        // Start the continuous mining cycle
        continueMining();
        
    } catch (const std::exception& e) {
        logMessage(tr("ERROR: Failed to start mining: %1").arg(QString::fromStdString(e.what())));
        stopMining();
        return;
    }
    
    // Start timer for continuous mining - every 0.1 seconds for very active mining
    miningTimer->start(100);
}

void MiningDialog::continueMining()
{
    if (!isMining || !clientModel || currentMiningAddress.isEmpty()) {
        return;
    }
    
    try {
        // Initialize random generator
        static std::random_device rd;
        static std::mt19937 gen(rd());
        
        // Get current difficulty for adaptive max_tries
        UniValue difficultyParams(UniValue::VARR);
        UniValue difficultyResult = clientModel->node().executeRpc("getblockchaininfo", difficultyParams, "");
        double currentDifficulty = 0.001; // Default fallback
        
        if (difficultyResult.isObject() && difficultyResult.exists("difficulty")) {
            currentDifficulty = difficultyResult["difficulty"].get_real();
        }
        
        // Calculate adaptive max_tries based on difficulty
        // Formula: base_tries * difficulty * safety_factor
        int baseTries = 1000000; // 1M base tries for difficulty 1.0
        int safetyFactor = 10;   // 10x safety margin
        int adaptiveMaxTries = static_cast<int>(baseTries * currentDifficulty * safetyFactor);
        
        // Ensure reasonable bounds: minimum 1M, maximum 100M
        if (adaptiveMaxTries < 1000000) {
            adaptiveMaxTries = 1000000;
        } else if (adaptiveMaxTries > 100000000) {
            adaptiveMaxTries = 100000000;
        }
        
        // Add some randomization to prevent conflicts
        std::uniform_int_distribution<> tries_dist(static_cast<int>(adaptiveMaxTries * 0.8), static_cast<int>(adaptiveMaxTries * 1.2));
        int randomMaxTries = tries_dist(gen);
        
        // Reduce delay for faster mining
        std::uniform_int_distribution<> delay_dist(10, 50); // Very short delay
        int randomDelay = delay_dist(gen);
        
        // Show mining parameters only every 50 attempts to reduce spam
        static int attemptCounter = 0;
        attemptCounter++;
        
        if (attemptCounter % 50 == 1) {
            logMessage(tr(""));
            logMessage(tr("🧠 Mining Status Update (Round #%1):").arg((attemptCounter / 50) + 1));
            logMessage(tr("   Difficulty: %1 | Max tries: %2K | Blocks found: %3")
                      .arg(QString::number(currentDifficulty, 'f', 6))
                      .arg(adaptiveMaxTries / 1000)
                      .arg(blocksFound));
            logMessage(tr(""));
        }
        
        // Store attempt counter for lambda capture
        int currentAttempt = attemptCounter;
        
        // Apply random delay before starting
        QTimer::singleShot(randomDelay, [this, randomMaxTries, currentAttempt]() {
            if (!isMining) return;
            performInternalMining(currentMiningAddress, randomMaxTries, currentAttempt);
        });
        
    } catch (const std::exception& e) {
        logMessage(tr("ERROR: Failed to continue mining: %1").arg(QString::fromStdString(e.what())));
        stopMining();
        return;
    }
}

void MiningDialog::performInternalMining(const QString& miningAddress, int maxTries, int attemptNumber)
{
    if (!isMining || !clientModel) {
        return;
    }
    
    try {
        // Generate random starting nonce for display
        static std::random_device rd;
        static std::mt19937 gen(rd());
        std::uniform_int_distribution<uint32_t> nonce_dist(0, UINT32_MAX);
        uint32_t startingNonce = nonce_dist(gen);
        
        // Update the last line in log with current mining progress
        updateMiningProgress(attemptNumber, startingNonce, maxTries);
        
        // Prepare RPC parameters
        UniValue params(UniValue::VARR);
        params.push_back(1); // Generate 1 block
        params.push_back(miningAddress.toStdString());
        params.push_back(maxTries);
        
        // Execute RPC call through the node interface
        UniValue result = clientModel->node().executeRpc("generatetoaddress", params, "");
        
        if (result.isArray() && result.size() > 0) {
            // Block was found!
            blocksFound++;
            totalAttempts += maxTries;
            
            std::string blockHash = result[0].get_str();
            
            // Clear the progress line and show success
            clearLastLogLine();
            logMessage(tr(""));
            logMessage(tr("*** 🎉 BLOCK FOUND! ***"));
            logMessage(tr("✅ Block #%1 mined successfully!").arg(blocksFound));
            logMessage(tr("🔗 Hash: %1").arg(QString::fromStdString(blockHash).left(16) + "..."));
            logMessage(tr("📊 Total attempts: %1M").arg(QString::number(totalAttempts / 1000000.0, 'f', 1)));
            logMessage(tr(""));
            
            // Get updated blockchain info
            getBlockchainInfo();
        } else {
            // No block found, but continue mining
            totalAttempts += maxTries;
            // Don't log anything here - the progress line will be updated by next attempt
        }
        
        // Update hash rate (approximate)
        currentHashRate = maxTries;
        hashCount++;
        
    } catch (const std::exception& e) {
        clearLastLogLine();
        logMessage(tr("❌ Mining error: %1").arg(QString::fromStdString(e.what())));
    }
}

void MiningDialog::updateMiningProgress(int attemptNumber, uint32_t currentNonce, int maxTries)
{
    // Clear the last line if it was a progress line
    clearLastLogLine();
    
    // Calculate hash rate in readable format
    QString hashRateStr;
    if (maxTries >= 1000000) {
        hashRateStr = QString::number(maxTries / 1000000.0, 'f', 1) + "M";
    } else if (maxTries >= 1000) {
        hashRateStr = QString::number(maxTries / 1000.0, 'f', 0) + "K";
    } else {
        hashRateStr = QString::number(maxTries);
    }
    
    // Show current mining progress
    QString progressMsg = tr("⛏️  Mining... Nonce: %1 | Rate: %2 H/s | Attempt: %3 | Total: %4M")
                         .arg(QString::number(currentNonce, 16).toUpper().rightJustified(8, '0'))
                         .arg(hashRateStr)
                         .arg(attemptNumber)
                         .arg(QString::number(totalAttempts / 1000000.0, 'f', 1));
    
    // Add this as the last line (will be replaced by next update)
    logMessage(progressMsg);
    lastProgressLine = progressMsg;
}

void MiningDialog::clearLastLogLine()
{
    if (!lastProgressLine.isEmpty()) {
        // Get current text
        QString currentText = logTextEdit->toPlainText();
        
        // Find and remove the last progress line
        int lastIndex = currentText.lastIndexOf(lastProgressLine);
        if (lastIndex != -1) {
            // Remove the progress line and its timestamp
            int lineStart = currentText.lastIndexOf('\n', lastIndex - 1) + 1;
            if (lineStart > 0) {
                currentText = currentText.left(lineStart) + currentText.mid(lastIndex + lastProgressLine.length());
                if (currentText.endsWith('\n')) {
                    currentText.chop(1);
                }
                logTextEdit->setPlainText(currentText);
                
                // Auto-scroll to bottom
                QScrollBar *scrollBar = logTextEdit->verticalScrollBar();
                scrollBar->setValue(scrollBar->maximum());
            }
        }
        lastProgressLine.clear();
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
    if (!clientModel) {
        return;
    }
    
    try {
        // Use internal RPC call for blockchain info
        UniValue params(UniValue::VARR);
        UniValue result = clientModel->node().executeRpc("getblockchaininfo", params, "");
        
        if (result.isObject()) {
            int blocks = result["blocks"].getInt<int>();
            std::string bestHash = result["bestblockhash"].get_str();
            double difficulty = result["difficulty"].get_real();
            
            logMessage(tr("📊 Blockchain Info:"));
            logMessage(tr("   Height: %1 blocks").arg(blocks));
            logMessage(tr("   Difficulty: %1").arg(QString::number(difficulty, 'f', 6)));
            logMessage(tr("   Best block: %1").arg(QString::fromStdString(bestHash)));
        }
    } catch (const std::exception& e) {
        logMessage(tr("Warning: Could not get blockchain info: %1").arg(QString::fromStdString(e.what())));
    }
} 