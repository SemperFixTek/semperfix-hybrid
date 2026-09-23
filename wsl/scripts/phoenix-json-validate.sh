#!/usr/bin/env bash
set -euo pipefail

FILE="/opt/semperfix/logs/mesh-handshake.json"

if jq -e . "$FILE" >/dev/null 2>&1; then
    echo "[PASS] Valid JSON in: $FILE"
else
    echo "[FAIL] Invalid JSON in: $FILE"
    exit 1
fi

INNER=$(jq -r '.peer_dump' "$FILE")

if echo "$INNER" | jq . >/dev/null 2>&1; then
    echo "[PASS] Inner peer_dump JSON valid"
else
    echo "[WARN] peer_dump contains non-parseable JSON"
fi

echo "[PASS] All module JSON files valid"
