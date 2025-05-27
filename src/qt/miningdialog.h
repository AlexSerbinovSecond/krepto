#ifndef BITCOIN_QT_MININGDIALOG_H
#define BITCOIN_QT_MININGDIALOG_H

#include <QDialog>
#include <QTextEdit>
#include <QTimer>
#include <QThread>
#include <QMutex>
#include <QProgressBar>
#include <QLabel>
#include <QPushButton>
#include <QVBoxLayout>
#include <QHBoxLayout>

class ClientModel;
class WalletModel;

QT_BEGIN_NAMESPACE
class QTimer;
QT_END_NAMESPACE

/** Mining dialog with real-time hash rate display and logging */
class MiningDialog : public QDialog
{
    Q_OBJECT

public:
    explicit MiningDialog(QWidget *parent = nullptr);
    ~MiningDialog();

    void setClientModel(ClientModel *clientModel);
    void setWalletModel(WalletModel *walletModel);

public Q_SLOTS:
    void startMining();
    void stopMining();
    void updateMiningLog(const QString &message);
    void updateHashRate(double hashRate);
    void updateProgress(int blocksFound, int totalAttempts);
    void syncMiningState(bool mining);

Q_SIGNALS:
    void miningStarted();
    void miningStopped();

private Q_SLOTS:
    void updateDisplay();

private:
    void setupUI();
    void logMessage(const QString &message);
    void simulateMining();
    void getBlockchainInfo();

    ClientModel *clientModel;
    WalletModel *walletModel;
    
    // UI elements
    QTextEdit *logTextEdit;
    QProgressBar *progressBar;
    QLabel *hashRateLabel;
    QLabel *statusLabel;
    QLabel *blocksFoundLabel;
    QPushButton *startButton;
    QPushButton *stopButton;
    QPushButton *clearLogButton;
    
    // Mining state
    QTimer *updateTimer;
    bool isMining;
    int blocksFound;
    int totalAttempts;
    double currentHashRate;
    
    // Mining simulation state
    int blockHeight;
    uint32_t currentNonce;
    int hashCount;
    
    // Thread safety
    QMutex logMutex;
};

#endif // BITCOIN_QT_MININGDIALOG_H 