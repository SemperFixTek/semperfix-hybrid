#!/usr/bin/env bash
set -euo pipefail

STATUS_PATH="/mnt/c/SemperFix/ConfigBackup/phoenix-status.json"

SUP_OK=false
API_OK=false
STATUS_OK=false
API_URL=""

if [ -f "$STATUS_PATH" ]; then
  API_OK="$(jq -r '.ApiOK' "$STATUS_PATH")"
  STATUS_OK="$(jq -r '.StatusOK' "$STATUS_PATH")"
  API_URL="$(jq -r '.ApiUrl' "$STATUS_PATH")"

  if [ "$API_OK" = "true" ] && [ "$STATUS_OK" = "true" ]; then
    SUP_OK=true
  fi
fi

TS="$(date --iso-8601=seconds)"

cat <<EOF
{
  "SupervisorOK": $SUP_OK,
  "ApiOK": $API_OK,
  "StatusOK": $STATUS_OK,
  "ApiUrl": "$API_URL",
  "Timestamp": "$TS"
}
EOF
