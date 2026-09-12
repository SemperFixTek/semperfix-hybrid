#!/bin/bash
set -euo pipefail

PHOENIX_FILE="/mnt/c/SemperFix/ConfigBackup/phoenix.json"
API_URL=$(jq -r '.ApiUrl' "$PHOENIX_FILE")

CONFIG_FILE="/mnt/c/SemperFix/ConfigBackup/syncthing-config.json"
API_KEY=$(jq -r '.gui.apikey' "$CONFIG_FILE")

SERVICE_OK=false
if curl -s -H "X-API-Key: $API_KEY" "$API_URL/rest/system/status" >/dev/null; then
    SERVICE_OK=true
fi


if $CONFIG_OK && $SERVICE_OK; then
    VERIFY_OK=true
fi

jq -n \
  --argjson ConfigOK "$CONFIG_OK" \
  --argjson ServiceOK "$SERVICE_OK" \
  --argjson VerifyOK "$VERIFY_OK" \
  '{
    VerifyOK: $VerifyOK,
    ConfigOK: $ConfigOK,
    ServiceOK: $ServiceOK
  }'
