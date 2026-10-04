#!/usr/bin/env bash
set -euo pipefail

# Phoenix v2 Standard Environment Header
umask 002

# Ensure consistent locale + predictable JSON behavior
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

# Ensure logs and state directories exist
mkdir -p /var/lib/semperfix/state
mkdir -p /opt/semperfix/logs

# Safety: prevent Windows CRLF issues
dos2unix "$0" 2>/dev/null || true


FILE="/opt/semperfix/logs/mesh-handshake.json"

# ---------- Validate outer JSON ----------
if jq -e . "$FILE" >/dev/null 2>&1; then
    echo "[PASS] Valid JSON in: $FILE"
else
    echo "[FAIL] Invalid JSON in: $FILE"
    exit 1
fi

# ---------- Validate peer_dump (must be an object) ----------
if jq -e '.peer_dump | objects' "$FILE" >/dev/null 2>&1; then
    echo "[PASS] peer_dump is valid JSON object"
else
    echo "[FAIL] peer_dump is missing or not a JSON object"
    exit 1
fi

echo "[PASS] All module JSON files valid"
