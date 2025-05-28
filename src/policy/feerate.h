// Copyright (c) 2009-2010 Katoshi Nakamoto
// Copyright (c) 2009-2022 The Krepto core developers
// Distributed under the MIT software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#ifndef BITCOIN_POLICY_FEERATE_H
#define BITCOIN_POLICY_FEERATE_H

#include <consensus/amount.h>
#include <serialize.h>


#include <cstdint>
#include <string>
#include <type_traits>

const std::string CURRENCY_UNIT = "BTC"; // One formatted unit
const std::string CURRENCY_ATOM = "kat"; // One indivisible minimum value unit

/* Used to determine type of fee estimation requested */
enum class FeeEstimateMode {
    UNSET,        //!< Use default settings based on other criteria
    ECONOMICAL,   //!< Force estimateSmartFee to use non-conservative estimates
    CONSERVATIVE, //!< Force estimateSmartFee to use conservative estimates
    BTC_KVB,      //!< Use BTC/kvB fee rate unit
    SAT_VB,       //!< Use kat/vB fee rate unit
};

/**
 * Fee rate in katoshis per kilovirtualbyte: CAmount / kvB
 */
class CFeeRate
{
private:
    /** Fee rate in kat/kvB (katoshis per 1000 virtualbytes) */
    CAmount nKatoshisPerK;

public:
    /** Fee rate of 0 katoshis per kvB */
    CFeeRate() : nKatoshisPerK(0) { }
    template<std::integral I> // Disallow silent float -> int conversion
    explicit CFeeRate(const I _nKatoshisPerK): nKatoshisPerK(_nKatoshisPerK) {
    }

    /**
     * Construct a fee rate from a fee in katoshis and a vsize in vB.
     *
     * param@[in]   nFeePaid    The fee paid by a transaction, in katoshis
     * param@[in]   num_bytes   The vsize of a transaction, in vbytes
     */
    CFeeRate(const CAmount& nFeePaid, uint32_t num_bytes);

    /**
     * Return the fee in katoshis for the given vsize in vbytes.
     * If the calculated fee would have fractional katoshis, then the
     * returned fee will always be rounded up to the nearest katoshi.
     */
    CAmount GetFee(uint32_t num_bytes) const;

    /**
     * Return the fee in katoshis for a vsize of 1000 vbytes
     */
    CAmount GetFeePerK() const { return nKatoshisPerK; }
    friend bool operator<(const CFeeRate& a, const CFeeRate& b) { return a.nKatoshisPerK < b.nKatoshisPerK; }
    friend bool operator>(const CFeeRate& a, const CFeeRate& b) { return a.nKatoshisPerK > b.nKatoshisPerK; }
    friend bool operator==(const CFeeRate& a, const CFeeRate& b) { return a.nKatoshisPerK == b.nKatoshisPerK; }
    friend bool operator<=(const CFeeRate& a, const CFeeRate& b) { return a.nKatoshisPerK <= b.nKatoshisPerK; }
    friend bool operator>=(const CFeeRate& a, const CFeeRate& b) { return a.nKatoshisPerK >= b.nKatoshisPerK; }
    friend bool operator!=(const CFeeRate& a, const CFeeRate& b) { return a.nKatoshisPerK != b.nKatoshisPerK; }
    CFeeRate& operator+=(const CFeeRate& a) { nKatoshisPerK += a.nKatoshisPerK; return *this; }
    std::string ToString(const FeeEstimateMode& fee_estimate_mode = FeeEstimateMode::BTC_KVB) const;
    friend CFeeRate operator*(const CFeeRate& f, int a) { return CFeeRate(a * f.nKatoshisPerK); }
    friend CFeeRate operator*(int a, const CFeeRate& f) { return CFeeRate(a * f.nKatoshisPerK); }

    SERIALIZE_METHODS(CFeeRate, obj) { READWRITE(obj.nKatoshisPerK); }
};

#endif // BITCOIN_POLICY_FEERATE_H
