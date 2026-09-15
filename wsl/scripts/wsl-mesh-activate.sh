#!/usr/bin/env bash
set -euo pipefail

CFG_PATH="/mnt/c/SemperFix/Phoenix/phoenix.json"

if [ ! -f "$CFG_PATH" ]; then
  echo '{"ActivationOK":false,"Reason":"phoenix.json not found"}'
  exit 1
fi

API_URL="$(jq -r '.ApiUrl' "$CFG_PATH")"
API_KEY="$(jq -r '.ApiKey' "$CFG_PATH")"
ROLE="$(jq -r '.NodeRole' "$CFG_PATH")"

OK=false
REASON=""

if curl -s -m 4 -H "X-API-Key: $API_KEY" "$API_URL/rest/system/ping" | jq -e '.ping == "pong"' >/dev/null 2>&1; then
  OK=true
else
  REASON="Ping did not return pong"
fi

TS="$(date --iso-8601=seconds)"

cat <<EOF
{
  "ActivationOK": $OK,
  "Reason": "$REASON",
  "ApiUrl": "$API_URL",
  "NodeRole": "$ROLE",
  "Timestamp": "$TS"
}
EOF
