#!/usr/bin/env bash
set -euo pipefail

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
