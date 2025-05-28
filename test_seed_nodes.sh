#!/bin/bash

echo "🌐 Testing Krepto Seed Nodes Connectivity..."
echo "============================================="

# Список робочих seed нод
NODES=(
    "164.68.117.90:12345"
    "5.189.133.204:12345"
)

WORKING_NODES=0
TOTAL_NODES=${#NODES[@]}

echo "Testing $TOTAL_NODES seed nodes..."
echo ""

for node in "${NODES[@]}"; do
    IFS=':' read -r ip port <<< "$node"
    echo -n "Testing $node... "
    
    if nc -z -w5 "$ip" "$port" 2>/dev/null; then
        echo "✅ ONLINE"
        ((WORKING_NODES++))
    else
        echo "❌ OFFLINE"
    fi
done

echo ""
echo "============================================="
echo "Results: $WORKING_NODES/$TOTAL_NODES nodes are online"

if [ $WORKING_NODES -eq 0 ]; then
    echo "⚠️  WARNING: No seed nodes are available!"
    echo "   Network connectivity may be limited."
elif [ $WORKING_NODES -eq $TOTAL_NODES ]; then
    echo "🎉 EXCELLENT: All seed nodes are online!"
    echo "   Network connectivity is optimal."
else
    echo "✅ GOOD: Some seed nodes are online."
    echo "   Network connectivity should work."
fi

echo ""
echo "💡 Tips:"
echo "   - If nodes are offline, check your internet connection"
echo "   - Firewall may be blocking port 12345"
echo "   - Try connecting manually: nc -v [IP] 12345"
echo "" 