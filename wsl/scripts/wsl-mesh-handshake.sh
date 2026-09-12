#!/bin/bash
# Mesh v2 — wsl-mesh-handshake.sh (Final Redesign)
# WSL-side identity + endpoint handshake
# Outputs guaranteed-valid JSON for Windows Mesh scripts

set -euo pipefail

PHOENIX_DIR="/mnt/c/SemperFix/ConfigBackup"

# ------------------------------------------------------------
# SELECT PHOENIX FILE (cluster or full topology only)
# ------------------------------------------------------------
PHOENIX_FILE=$(ls -1t "$PHOENIX_DIR"/phoenix.json "$PHOENIX_DIR"/phoenix.cluster.json 2>/dev/null | head -n 1 || true)

if [ -z "$PHOENIX_FILE" ]; then
    jq -n --arg dir "$PHOENIX_DIR" '{Error:"No usable phoenix.json or phoenix.cluster.json found", Directory:$dir}'
    exit 1
fi

# ------------------------------------------------------------
# LOAD PHOENIX JSON
# ------------------------------------------------------------
PHOENIX_JSON=$(cat "$PHOENIX_FILE")
NODE_ROLE=$(echo "$PHOENIX_JSON" | jq -r '.NodeRole // empty')

if [ -z "$NODE_ROLE" ]; then
    jq -n --arg file "$PHOENIX_FILE" '{Error:"NodeRole missing in phoenix file", File:$file}'
    exit 1
fi

# ------------------------------------------------------------
# EXTRACT NODE ENTRY (cluster or single-node schema)
# ------------------------------------------------------------
HAS_NODES=$(echo "$PHOENIX_JSON" | jq 'has("Nodes")')

if [ "$HAS_NODES" = "true" ]; then
    NODE_ENTRY=$(echo "$PHOENIX_JSON" | jq --arg role "$NODE_ROLE" '.Nodes[] | select(.Name==$role)')
else
    NODE_ENTRY=$(echo "$PHOENIX_JSON")
fi

API_URL=$(echo "$NODE_ENTRY" | jq -r '.ApiUrl // empty')
MESH_ENDPOINT=$(echo "$NODE_ENTRY" | jq -r '.MeshEndpoint // empty')

if [ -z "$API_URL" ] || [ -z "$MESH_ENDPOINT" ]; then
    jq -n --arg file "$PHOENIX_FILE" '{Error:"Phoenix file missing ApiUrl or MeshEndpoint", File:$file}'
    exit 1
fi

# ------------------------------------------------------------
# SYNCTHING IDENTITY CHECK
# ------------------------------------------------------------
IDENTITY_OK=false
IDENTITY_REASON=""
DEVICE_ID=""

STATUS_JSON=$(curl -s --max-time 4 "$API_URL/rest/system/status" || true)

if echo "$STATUS_JSON" | jq -e 'has("myID")' >/dev/null 2>&1; then
    DEVICE_ID=$(echo "$STATUS_JSON" | jq -r '.myID // empty')
    if [ -n "$DEVICE_ID" ]; then
        IDENTITY_OK=true
    else
        IDENTITY_REASON="Syncthing returned empty device ID"
    fi
else
    IDENTITY_REASON="Syncthing status unreachable"
fi

# ------------------------------------------------------------
# QUIC ENDPOINT CHECK
# ------------------------------------------------------------
QUIC_OK=false

EP=$(echo "$MESH_ENDPOINT" | sed 's|quic://||')
HOST=$(echo "$EP" | cut -d':' -f1)
PORT=$(echo "$EP" | cut -d':' -f2)

if timeout 2 bash -c "</dev/tcp/$HOST/$PORT" 2>/dev/null; then
    QUIC_OK=true
fi

# ------------------------------------------------------------
# DISCOVER OTHER ENDPOINTS (cluster only)
# ------------------------------------------------------------
OTHER_ENDPOINTS="{}"

if [ "$HAS_NODES" = "true" ]; then
    OTHER_ENDPOINTS=$(echo "$PHOENIX_JSON" | jq --arg role "$NODE_ROLE" '
        .Nodes
        | map(select(.Name != $role))
        | map({key: .Name, value: {ApiUrl: .ApiUrl, MeshEndpoint: .MeshEndpoint}})
        | from_entries
    ')
fi

# ------------------------------------------------------------
# OUTPUT FINAL JSON
# ------------------------------------------------------------
jq -n \
  --arg NodeRole "$NODE_ROLE" \
  --arg IdentityReason "$IDENTITY_REASON" \
  --arg DeviceID "$DEVICE_ID" \
  --arg MyEndpoint "$MESH_ENDPOINT" \
  --arg Timestamp "$(date -Iseconds)" \
  --argjson IdentityOK "$IDENTITY_OK" \
  --argjson EndpointOK "$QUIC_OK" \
  --argjson OtherEndpoints "$OTHER_ENDPOINTS" \
  '{
    NodeRole: $NodeRole,
    Handshake: {
      IdentityOK: $IdentityOK,
      IdentityReason: $IdentityReason,
      DeviceID: $DeviceID,
      EndpointOK: $EndpointOK,
      MyEndpoint: $MyEndpoint,
      OtherEndpoints: $OtherEndpoints,
      Timestamp: $Timestamp
    }
  }'
