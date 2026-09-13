#!/bin/bash

STATUS="/mnt/c/SemperFix/ConfigBackup/phoenix-status.json"
HB="/mnt/c/SemperFix/ConfigBackup/phoenix-heartbeat.json"

STATUS_OK=false
HB_OK=false

if [ -f "$STATUS" ]; then
    API_OK=$(jq -r '.ApiOK' "$STATUS")
    ST_OK=$(jq -r '.StatusOK' "$STATUS")
    if [ "$API_OK" = "true" ] && [ "$ST_OK" = "true" ]; then
        STATUS_OK=true
    fi
fi

if [ -f "$HB" ]; then
    TS=$(jq -r '.Timestamp' "$HB")
    NOW=$(date -Iseconds)
    DIFF=$(( $(date -d "$NOW" +%s) - $(date -d "$TS" +%s) ))
    if [ $DIFF -lt 120 ]; then
        HB_OK=true
    fi
fi

FAILOVER=$([ "$STATUS_OK" = "true" ] && [ "$HB_OK" = "true" ] && echo false || echo true)

echo "{
  \"FailoverRequired\":$FAILOVER,
  \"StatusOK\":$STATUS_OK,
  \"HeartbeatOK\":$HB_OK,
  \"Timestamp\":\"$(date -Iseconds)\"
}"
