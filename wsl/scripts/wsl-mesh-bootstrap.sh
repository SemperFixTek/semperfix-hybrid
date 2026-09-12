#!/bin/bash

CONFIG="/mnt/c/SemperFix/ConfigBackup/phoenix.json"

if [ ! -f "$CONFIG" ]; then
    echo '{"BootstrapOK":false,"Reason":"Missing phoenix.json"}'
    exit 1
fi

API_URL=$(jq -r '.ApiUrl' "$CONFIG")
API_KEY=$(jq -r '.ApiKey' "$CONFIG")

PONG=$(curl -s -H "X-API-Key: $API_KEY" "$API_URL/rest/system/ping")

if echo "$PONG" | jq -e '.ping=="pong"' >/dev/null; then
    echo "{\"BootstrapOK\":true,\"ApiUrl\":\"$API_URL\",\"ApiOK\":true}"
else
    echo "{\"BootstrapOK\":false,\"ApiUrl\":\"$API_URL\",\"ApiOK\":false}"
fi
