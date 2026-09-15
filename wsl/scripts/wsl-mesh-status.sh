#!/usr/bin/env bash
set -euo pipefail

CFG_PATH="/mnt/c/SemperFix/Phoenix/phoenix.json"

if [ ! -f "$CFG_PATH" ]; then
  echo '{"ApiOK":false,"StatusOK":false,"Reason":"phoenix.json not found"}'
  exit 1
fi

API_URL="$(jq -r '.ApiUrl' "$CFG_PATH")"
API_KEY="$(jq -r '.ApiKey' "$CFG_PATH")"
ROLE="$(jq -r '.NodeRole' "$CFG_PATH")"

API_OK=false
STATUS_OK=false

if curl -s -m 4 -H "X-API-Key: $API_KEY" "$API_URL/rest/system/ping" | jq -e '.ping == "pong"' >/dev/null 2>&1; then
  API_OK=true
fi

if curl -s -m 4 -H "X-API-Key: $API_KEY" "$API_URL/rest/system/status" | jq -e '.myID != null' >/dev/null 2>&1; then
  STATUS_OK=true
fi

TS="$(date --iso-8601=seconds)"

cat <<EOF
{
  "NodeRole": "$ROLE",
  "ApiUrl": "$API_URL",
  "ApiOK": $API_OK,
  "StatusOK": $STATUS_OK,
  "Timestamp": "$TS"
}
EOF
