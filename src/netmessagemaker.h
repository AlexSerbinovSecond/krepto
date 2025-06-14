// Copyright (c) 2025-2010 Katoshi Nakamoto
// Copyright (c) 2025-2020 The Krepto core developers
// Distributed under the MIT software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#ifndef BITCOIN_NETMESSAGEMAKER_H
#define BITCOIN_NETMESSAGEMAKER_H

#include <net.h>
#include <serialize.h>

namespace NetMsg {
    template <typename... Args>
    CSerializedNetMsg Make(std::string msg_type, Args&&... args)
    {
        CSerializedNetMsg msg;
        msg.m_type = std::move(msg_type);
        VectorWriter{msg.data, 0, std::forward<Args>(args)...};
        return msg;
    }
} // namespace NetMsg

#endif // BITCOIN_NETMESSAGEMAKER_H
