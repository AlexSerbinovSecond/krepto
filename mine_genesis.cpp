#include <iostream>
#include <iomanip>
#include <chrono>
#include "primitives/block.h"
#include "uint256.h"
#include "util/strencodings.h"
#include "crypto/sha256.h"

// Simple genesis block miner
int main() {
    // Genesis block parameters
    uint32_t nTime = 1748270717;
    uint32_t nBits = 0x1d00ffff; // Standard Bitcoin difficulty
    int32_t nVersion = 1;
    uint64_t nReward = 5000000000; // 50 KREPTO
    
    // Target for mainnet (8 leading zeros)
    uint256 target;
    target.SetCompact(nBits);
    
    std::cout << "Mining genesis block for Krepto mainnet..." << std::endl;
    std::cout << "Target: " << target.ToString() << std::endl;
    
    // Create genesis block structure
    CBlockHeader header;
    header.nVersion = nVersion;
    header.hashPrevBlock.SetNull();
    header.hashMerkleRoot = uint256{"5976614bb121054435ae20ef7100ecc07f176b54a7bf908493272d716f8409b4"};
    header.nTime = nTime;
    header.nBits = nBits;
    header.nNonce = 0;
    
    auto start_time = std::chrono::high_resolution_clock::now();
    uint32_t nonce = 0;
    
    while (true) {
        header.nNonce = nonce;
        uint256 hash = header.GetHash();
        
        if (hash <= target) {
            std::cout << "Found valid genesis block!" << std::endl;
            std::cout << "Nonce: " << nonce << std::endl;
            std::cout << "Hash: " << hash.ToString() << std::endl;
            std::cout << "Time: " << nTime << std::endl;
            std::cout << "Bits: 0x" << std::hex << nBits << std::dec << std::endl;
            break;
        }
        
        nonce++;
        if (nonce % 100000 == 0) {
            auto current_time = std::chrono::high_resolution_clock::now();
            auto duration = std::chrono::duration_cast<std::chrono::seconds>(current_time - start_time);
            std::cout << "Tried " << nonce << " nonces in " << duration.count() << " seconds" << std::endl;
        }
    }
    
    return 0;
} 