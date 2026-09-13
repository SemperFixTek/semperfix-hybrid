#!/usr/bin/env bash
set -euo pipefail

CFG_PATH="/mnt/c/SemperFix/Phoenix/phoenix.json"

if [ ! -f "$CFG_PATH" ]; then
  echo '{"Error":"phoenix.json not found"}'
  exit 1
fi

API_URL="$(jq -r '.ApiUrl' "$CFG_PATH")"
API_KEY="$(jq -r '.ApiKey' "$CFG_PATH")"
ROLE="$(jq -r '.NodeRole' "$CFG_PATH")"
MESH_EP="$(jq -r '.MeshEndpoint // empty' "$CFG_PATH")"

IDENTITY_OK=false
IDENTITY_REASON=""
DEVICE_ID=""

if STATUS_JSON="$(curl -s -m 4 -H "X-API-Key: $API_KEY" "$API_URL/rest/system/status")"; then
  if echo "$STATUS_JSON" | jq -e '.myID != null' >/dev/null 2>&1; then
    IDENTITY_OK=true
    DEVICE_ID="$(echo "$STATUS_JSON" | jq -r '.myID')"
  else
    IDENTITY_REASON="Syncthing returned empty device ID"
  fi
else
  IDENTITY_REASON="Syncthing status unreachable"
fi

ENDPOINT_OK=false
if [ -n "$MESH_EP" ]; then
  EP="${MESH_EP#quic://}"
  HOST="${EP%%:*}"
  PORT="${EP##*:}"
  if timeout 3 bash -c "echo > /dev/tcp/$HOST/$PORT" >/dev/null 2>&1; then
    ENDPOINT_OK=true
  fi
fi

TS="$(date --iso-8601=seconds)"

cat <<EOF
{
  "NodeRole": "$ROLE",
  "ApiUrl": "$API_URL",
  "IdentityOK": $IDENTITY_OK,
  "IdentityReason": "$IDENTITY_REASON",
  "DeviceID": "$DEVICE_ID",
  "EndpointOK": $ENDPOINT_OK,
  "Timestamp": "$TS"
}
EOF
