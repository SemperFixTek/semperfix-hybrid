#!/bin/bash

CONFIG="/mnt/c/SemperFix/ConfigBackup/phoenix.json"

if [ ! -f "$CONFIG" ]; then
    echo '{"VerifyOK":false,"Reason":"Missing phoenix.json"}'
    exit 1
fi

API_URL=$(jq -r '.ApiUrl' "$CONFIG")
API_KEY=$(jq -r '.ApiKey' "$CONFIG")

STATUS=$(curl -s -H "X-API-Key: $API_KEY" "$API_URL/rest/system/status")

if echo "$STATUS" | jq -e '.myID!=null' >/dev/null; then
    echo "{\"VerifyOK\":true,\"ApiUrl\":\"$API_URL\"}"
else
    echo "{\"VerifyOK\":false,\"ApiUrl\":\"$API_URL\"}"
fi
