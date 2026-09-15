#!/usr/bin/env bash
set -euo pipefail

CFG_PATH="/mnt/c/SemperFix/Phoenix/phoenix.json"
STATUS_PATH="/mnt/c/SemperFix/ConfigBackup/phoenix-status.json"

if [ ! -f "$CFG_PATH" ]; then
  echo '{"ApiOK":false,"StatusOK":false,"Reason":"phoenix.json not found"}'
  exit 1
fi

API_URL="$(jq -r '.ApiUrl' "$CFG_PATH")"
API_KEY="$(jq -r '.ApiKey' "$CFG_PATH")"

API_OK=false
STATUS_OK=false

# ping
if curl -s -m 4 -H "X-API-Key: $API_KEY" "$API_URL/rest/system/ping" | jq -e '.ping == "pong"' >/dev/null 2>&1; then
  API_OK=true
fi

# status
if curl -s -m 4 -H "X-API-Key: $API_KEY" "$API_URL/rest/system/status" | jq -e '.myID != null' >/dev/null 2>&1; then
  STATUS_OK=true
fi

TS="$(date --iso-8601=seconds)"

cat > "$STATUS_PATH" <<EOF
{
  "ApiOK": $API_OK,
  "StatusOK": $STATUS_OK,
  "ApiUrl": "$API_URL",
  "Timestamp": "$TS"
}
EOF

cat "$STATUS_PATH"
