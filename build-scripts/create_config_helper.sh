#!/bin/bash

# Helper script to create krepto.conf if it doesn't exist
# This ensures proper configuration for Windows and other platforms

CONFIG_DIR=""
CONFIG_FILE=""

# Detect platform and set appropriate paths
case "$(uname -s)" in
    Darwin*)
        CONFIG_DIR="$HOME/Library/Application Support/Krepto"
        ;;
    Linux*)
        CONFIG_DIR="$HOME/.krepto"
        ;;
    CYGWIN*|MINGW*|MSYS*)
        # Windows paths
        if [ -n "$LOCALAPPDATA" ]; then
            CONFIG_DIR="$LOCALAPPDATA/Krepto"
        elif [ -n "$APPDATA" ]; then
            CONFIG_DIR="$APPDATA/Krepto"
        else
            echo "Error: Cannot determine Windows config directory"
            exit 1
        fi
        ;;
esac

CONFIG_FILE="$CONFIG_DIR/krepto.conf"

# Create directory if it doesn't exist
mkdir -p "$CONFIG_DIR"

# Create config file if it doesn't exist
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Creating default krepto.conf at: $CONFIG_FILE"
    cat > "$CONFIG_FILE" << 'EOF'
# Krepto Configuration File

# Network Settings
port=12345
rpcport=12347

# Seed Nodes
addnode=164.68.117.90:12345
addnode=5.189.133.204:12345
connect=164.68.117.90:12345
connect=5.189.133.204:12345

# RPC Settings
rpcuser=kreptouser
rpcpassword=kreptopass123
rpcbind=127.0.0.1
rpcallowip=127.0.0.1

# Node Settings
daemon=0
server=1
listen=1

# Logging
debug=net
logips=1

# Performance
dbcache=512
maxmempool=300

# Wallet
disablewallet=0

# Force Krepto network (prevent Bitcoin connection)
onlynet=ipv4
discover=0
dnsseed=0

# Disable mining on client
gen=0
EOF
    echo "Default krepto.conf created successfully!"
else
    echo "krepto.conf already exists at: $CONFIG_FILE"
fi 