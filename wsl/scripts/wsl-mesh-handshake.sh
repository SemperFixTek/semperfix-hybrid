#!/bin/bash

CONFIG="/mnt/c/SemperFix/ConfigBackup/phoenix.json"

API_URL=$(jq -r '.ApiUrl' "$CONFIG")
API_KEY=$(jq -r '.ApiKey' "$CONFIG")
NODE_ROLE=$(jq -r '.NodeRole' "$CONFIG")

STATUS=$(curl -s -H "X-API-Key: $API_KEY" "$API_URL/rest/system/status")

IDENTITY_OK=false
DEVICE_ID=""

if echo "$STATUS" | jq -e '.myID!=null' >/dev/null; then
    IDENTITY_OK=true
    DEVICE_ID=$(echo "$STATUS" | jq -r '.myID')
fi

echo "{
  \"NodeRole\":\"$NODE_ROLE\",
  \"ApiUrl\":\"$API_URL\",
  \"IdentityOK\":$IDENTITY_OK,
  \"DeviceID\":\"$DEVICE_ID\",
  \"Timestamp\":\"$(date -Iseconds)\"
}"
