#!/usr/bin/env bash
set -euo pipefail

CFG_PATH="/mnt/c/SemperFix/Phoenix/phoenix.json"

if [ ! -f "$CFG_PATH" ]; then
  echo '{"VerifyOK":false,"VerifyReason":"phoenix.json not found"}'
  exit 1
fi

API_URL="$(jq -r '.ApiUrl' "$CFG_PATH")"
API_KEY="$(jq -r '.ApiKey' "$CFG_PATH")"
ROLE="$(jq -r '.NodeRole' "$CFG_PATH")"

VERIFY_OK=false
REASON=""

if curl -s -m 4 -H "X-API-Key: $API_KEY" "$API_URL/rest/system/config" | jq -e '.gui.enabled == true and .gui.address != null' >/dev/null 2>&1; then
  VERIFY_OK=true
else
  REASON="GUI not enabled or address missing"
fi

TS="$(date --iso-8601=seconds)"

cat <<EOF
{
  "NodeRole": "$ROLE",
  "ApiUrl": "$API_URL",
  "VerifyOK": $VERIFY_OK,
  "VerifyReason": "$REASON",
  "Timestamp": "$TS"
}
EOF
