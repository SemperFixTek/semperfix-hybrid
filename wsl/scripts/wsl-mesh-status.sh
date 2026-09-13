#!/bin/bash

CONFIG="/mnt/c/SemperFix/ConfigBackup/phoenix.json"

API_URL=$(jq -r '.ApiUrl' "$CONFIG")
API_KEY=$(jq -r '.ApiKey' "$CONFIG")

PING=$(curl -s -H "X-API-Key: $API_KEY" "$API_URL/rest/system/ping")
STATUS=$(curl -s -H "X-API-Key: $API_KEY" "$API_URL/rest/system/status")

API_OK=false
STATUS_OK=false

if echo "$PING" | jq -e '.ping=="pong"' >/dev/null; then
    API_OK=true
fi

if echo "$STATUS" | jq -e '.myID!=null' >/dev/null; then
    STATUS_OK=true
fi

echo "{\"ApiOK\":$API_OK,\"StatusOK\":$STATUS_OK,\"ApiUrl\":\"$API_URL\"}"
