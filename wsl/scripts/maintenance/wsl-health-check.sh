#!/usr/bin/env bash

echo "=== SemperFix WSL Health Check ==="

# --- Detect Distro ---
DISTRO=$(lsb_release -ds 2>/dev/null || echo "Unknown")
echo "WSL Distro: $DISTRO"

# --- Check Syncthing (WSL-side) ---
if pgrep -x syncthing >/dev/null 2>&1; then
    echo "Syncthing: RUNNING"
else
    echo "Syncthing: NOT RUNNING"
fi

# --- Check Windows API Bridge ---
# Use the JSON API endpoint instead of the HTML UI root
API_RESPONSE=$(curl -s http://localhost:8384/rest/system/ping)

if [[ "$API_RESPONSE" == *"pong"* ]]; then
    echo "Windows API: OK"
else
    echo "Windows API: FAILED"
fi

echo "Health check complete."
