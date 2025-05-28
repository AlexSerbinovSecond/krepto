#ifndef BITCOIN_QT_MININGDIALOG_H
#define BITCOIN_QT_MININGDIALOG_H

#include <QDialog>
#include <QTimer>
#include <QMutex>

// Add these includes for internal RPC
#include <interfaces/node.h>
#include <rpc/server.h>
#include <rpc/request.h>

class QTextEdit;
class QProgressBar;
class QLabel;
class QPushButton;
class ClientModel;
class WalletModel;

class MiningDialog : public QDialog
{
    Q_OBJECT

public:
    explicit MiningDialog(QWidget *parent = nullptr);
    ~MiningDialog();

    void setClientModel(ClientModel *model);
    void setWalletModel(WalletModel *model);

public Q_SLOTS:
    void startMining();
    void stopMining();
    void updateMiningLog(const QString &message);
    void updateHashRate(double hashRate);
    void updateProgress(int blocks, int attempts);
    void syncMiningState(bool mining);

Q_SIGNALS:
    void miningStarted();
    void miningStopped();

private Q_SLOTS:
    void updateDisplay();

private:
    void setupUI();
    void logMessage(const QString &message);
    void getBlockchainInfo();
    
    // New methods for internal RPC
    void continueMining();
    void performInternalMining(const QString& miningAddress, int maxTries, int attemptNumber);

    // UI components
    QTextEdit *logTextEdit;
    QProgressBar *progressBar;
    QLabel *statusLabel;
    QLabel *hashRateLabel;
    QLabel *blocksFoundLabel;
    QPushButton *startButton;
    QPushButton *stopButton;
    QPushButton *clearLogButton;

    // Models
    ClientModel *clientModel;
    WalletModel *walletModel;

    // Mining state
    bool isMining;
    int blocksFound;
    int totalAttempts;
    double currentHashRate;
    int blockHeight;
    uint64_t currentNonce;
    int hashCount;
    QString currentMiningAddress; // Store current mining address

    // Timers
    QTimer *updateTimer;
    QTimer *miningTimer;

    // Thread safety
    QMutex logMutex;
};

#endif // BITCOIN_QT_MININGDIALOG_H 