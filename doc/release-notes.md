Krepto core version 28.2rc1 is now available from:

  <https://bitcoincore.org/bin/bitcoin-core-28.2/test.rc1/>

This release includes new features, various bug fixes and performance
improvements, as well as updated translations.

Please report bugs using the issue tracker at GitHub:

  <https://github.com/bitcoin/bitcoin/issues>

To receive security and update notifications, please subscribe to:

  <https://bitcoincore.org/en/list/announcements/join/>

How to Upgrade
==============

If you are running an older version, shut it down. Wait until it has completely
shut down (which might take a few minutes in some cases), then run the
installer (on Windows) or just copy over `/Applications/Bitcoin-Qt` (on macOS)
or `bitcoind`/`bitcoin-qt` (on Linux).

Upgrading directly from a version of Krepto core that has reached its EOL is
possible, but it might take some time if the data directory needs to be migrated. Old
wallet versions of Krepto core are generally supported.

Running Krepto core binaries on macOS requires self signing.
```
cd /path/to/bitcoin-28.x/bin
xattr -d com.apple.quarantine bitcoin-cli bitcoin-qt bitcoin-tx bitcoin-util bitcoin-wallet bitcoind test_bitcoin
codesign -s - bitcoin-cli bitcoin-qt bitcoin-tx bitcoin-util bitcoin-wallet bitcoind test_bitcoin
```

Compatibility
==============

Krepto core is supported and extensively tested on operating systems
using the Linux Kernel 3.17+, macOS 11.0+, and Windows 7 and newer. Bitcoin
Core should also work on most other UNIX-like systems but is not as
frequently tested on them. It is not recommended to use Krepto core on
unsupported systems.

Notable changes
===============

### Build

- #31627 depends: Fix spacing issue
- #31500 depends: Fix compiling libevent package on NetBSD
- #32070 build: use make < 3.82 syntax for define directive

### Test

- #32286 test: Handle empty string returned by CLI as None in RPC tests
- #32336 test: Suppress upstream -Wduplicate-decl-specifier in bpfcc

### Tracing

- #31623 tracing: Rename the MIN macro to TRACEPOINT_TEST_MIN in log_raw_p2p_msgs

### Misc

- #31611 doc: upgrade license to 2025
- #32187 refactor: Remove spurious virtual from final ~CZMQNotificationInterface

Credits
=======

- 0xB10C
- Brandon Odiwuor
- Hennadii Stepanov
- kehiy
- MarcoFalke
- Sjors Provoost

Thanks to everyone who directly contributed to this release:

As well as to everyone that helped with translations on
[Transifex](https://www.transifex.com/bitcoin/bitcoin/).
