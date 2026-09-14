#!/usr/bin/env bash
set -euo pipefail

STATUS_PATH="/mnt/c/SemperFix/ConfigBackup/phoenix-status.json"
HB_PATH="/mnt/c/SemperFix/ConfigBackup/phoenix-heartbeat.json"
FO_PATH="/mnt/c/SemperFix/ConfigBackup/phoenix-failover.json"

STATUS_OK=false
HB_OK=false

if [ -f "$STATUS_PATH" ]; then
  STATUS_OK="$(jq -r '.ApiOK and .StatusOK' "$STATUS_PATH")"
fi

if [ -f "$HB_PATH" ]; then
  HB_TS="$(jq -r '.Timestamp' "$HB_PATH")"
  if [ "$HB_TS" != "null" ]; then
    # heartbeat within 2 minutes
    if [ $(( $(date +%s) - $(date -d "$HB_TS" +%s) )) -lt 120 ]; then
      HB_OK=true
    fi
  fi
fi

FAILOVER=true
if [ "$STATUS_OK" = "true" ] && [ "$HB_OK" = "true" ]; then
  FAILOVER=false
fi

TS="$(date --iso-8601=seconds)"

cat > "$FO_PATH" <<EOF
{
  "FailoverRequired": $FAILOVER,
  "StatusOK": $STATUS_OK,
  "HeartbeatOK": $HB_OK,
  "Timestamp": "$TS"
}
EOF

cat "$FO_PATH"
