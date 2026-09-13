#!/usr/bin/env bash
set -euo pipefail

STATUS_PATH="/mnt/c/SemperFix/ConfigBackup/phoenix-status.json"

if [ ! -f "$STATUS_PATH" ]; then
  echo '{"Valid":false,"Reason":"Missing phoenix-status.json"}'
  exit 1
fi

API_OK="$(jq -r '.ApiOK' "$STATUS_PATH")"
STATUS_OK="$(jq -r '.StatusOK' "$STATUS_PATH")"
API_URL="$(jq -r '.ApiUrl' "$STATUS_PATH")"

VALID=false
if [ "$API_OK" = "true" ] && [ "$STATUS_OK" = "true" ]; then
  VALID=true
fi

TS="$(date --iso-8601=seconds)"

cat <<EOF
{
  "Valid": $VALID,
  "ApiOK": $API_OK,
  "StatusOK": $STATUS_OK,
  "ApiUrl": "$API_URL",
  "Timestamp": "$TS"
}
EOF
