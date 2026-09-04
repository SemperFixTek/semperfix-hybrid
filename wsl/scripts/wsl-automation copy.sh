#!/usr/bin/env bash

LOG="/opt/semperfix/logs/automation.log"
mkdir -p /opt/semperfix/logs

echo "=== SemperFix WSL Automation ===" | tee -a "$LOG"
echo "Timestamp: $(date)" | tee -a "$LOG"

# --- Check Syncthing ---
if pgrep -x syncthing >/dev/null 2>&1; then
    echo "[OK] Syncthing running" | tee -a "$LOG"
else
    echo "[ERROR] Syncthing is not running" | tee -a "$LOG"
fi

# --- Ping Windows Syncthing API ---
API=$(curl -s --max-time 10 http://localhost:8384/rest/system/ping)

if [[ "$API" == *"pong"* ]]; then
    echo "[OK] Windows API reachable" | tee -a "$LOG"
else
    echo "[ERROR] Windows API unreachable or timed out" | tee -a "$LOG"
fi

# --- Trigger Windows automation ---
echo "[INFO] Calling Windows automation layer..." | tee -a "$LOG"
powershell.exe -Command "C:\SemperFix\Tools\semperfix-windows-automation.ps1" >> "$LOG" 2>&1

echo "[DONE] Automation cycle complete" | tee -a "$LOG"
