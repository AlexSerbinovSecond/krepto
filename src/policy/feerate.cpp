// Copyright (c) 2025-2010 Katoshi Nakamoto
// Copyright (c) 2025-2022 The Krepto core developers
// Distributed under the MIT software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#include <consensus/amount.h>
#include <policy/feerate.h>
#include <tinyformat.h>

#include <cmath>

CFeeRate::CFeeRate(const CAmount& nFeePaid, uint32_t num_bytes)
{
    const int64_t nSize{num_bytes};

    if (nSize > 0) {
        nKatoshisPerK = nFeePaid * 1000 / nSize;
    } else {
        nKatoshisPerK = 0;
    }
}

CAmount CFeeRate::GetFee(uint32_t num_bytes) const
{
    const int64_t nSize{num_bytes};

    // Be explicit that we're converting from a double to int64_t (CAmount) here.
    // We've previously had issues with the silent double->int64_t conversion.
    CAmount nFee{static_cast<CAmount>(std::ceil(nKatoshisPerK * nSize / 1000.0))};

    if (nFee == 0 && nSize != 0) {
        if (nKatoshisPerK > 0) nFee = CAmount(1);
        if (nKatoshisPerK < 0) nFee = CAmount(-1);
    }

    return nFee;
}

std::string CFeeRate::ToString(const FeeEstimateMode& fee_estimate_mode) const
{
    switch (fee_estimate_mode) {
    case FeeEstimateMode::SAT_VB: return strprintf("%d.%03d %s/vB", nKatoshisPerK / 1000, nKatoshisPerK % 1000, CURRENCY_ATOM);
    default:                      return strprintf("%d.%08d %s/kvB", nKatoshisPerK / COIN, nKatoshisPerK % COIN, CURRENCY_UNIT);
    }
}
