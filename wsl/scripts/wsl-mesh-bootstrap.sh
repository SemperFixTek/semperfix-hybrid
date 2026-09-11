#!/bin/bash
# Mesh v2 — wsl-mesh-bootstrap.sh
# WSL-side bootstrap validation
# Outputs JSON for Windows Mesh scripts to consume
# Never writes phoenix files directly

set -e

NODE_ROLE=""
PHOENIX_PATH_WIN="/mnt/c/SemperFix/ConfigBackup"

# ------------------------------------------------------------
# DETERMINE NODE ROLE BY READING WINDOWS PHOENIX FILE
# ------------------------------------------------------------
for f in "$PHOENIX_PATH_WIN"/phoenix.*.json; do
    if [ -f "$f" ]; then
        role=$(grep -o '"NodeRole"[[:space:]]*:[[:space:]]*"[^"]*"' "$f" | cut -d'"' -f4)
        if [ ! -z "$role" ]; then
            NODE_ROLE="$role"
            PHOENIX_FILE="$f"
            break
        fi
    fi
done

if [ -z "$NODE_ROLE" ]; then
    echo '{"Error":"No phoenix.<node>.json found"}'
    exit 1
fi

# ------------------------------------------------------------
# EXTRACT NODE API + MESH ENDPOINT
# ------------------------------------------------------------
API_URL=$(grep -A3 "\"Name\": \"$NODE_ROLE\"" "$PHOENIX_FILE" | grep '"ApiUrl"' | cut -d'"' -f4)
MESH_ENDPOINT=$(grep -A3 "\"Name\": \"$NODE_ROLE\"" "$PHOENIX_FILE" | grep '"MeshEndpoint"' | cut -d'"' -f4)

# ------------------------------------------------------------
# CHECK SYNCTHING API FROM WSL
# ------------------------------------------------------------
API_OK=false
if curl -s --max-time 3 "$API_URL/rest/system/ping" | grep -q "pong"; then
    API_OK=true
fi

# ------------------------------------------------------------
# CHECK QUIC ENDPOINT FROM WSL
# ------------------------------------------------------------
QUIC_OK=false
HOST=$(echo "$MESH_ENDPOINT" | sed 's/quic:\/\///' | cut -d':' -f1)
PORT=$(echo "$MESH_ENDPOINT" | sed 's/quic:\/\///' | cut -d':' -f2)

if timeout 2 bash -c "</dev/tcp/$HOST/$PORT" 2>/dev/null; then
    QUIC_OK=true
fi

# ------------------------------------------------------------
# CHECK BASIC WSL ENVIRONMENT
# ------------------------------------------------------------
WSL_OK=true

# Check if /opt/semperfix exists
if [ ! -d "/opt/semperfix" ]; then
    WSL_OK=false
fi

# Check if scripts directory exists
if [ ! -d "/opt/semperfix/scripts" ]; then
    WSL_OK=false
fi

# ------------------------------------------------------------
# OUTPUT JSON FOR WINDOWS MESH SCRIPTS
# ------------------------------------------------------------
cat <<EOF
{
  "NodeRole": "$NODE_ROLE",
  "Bootstrap": {
    "ApiReachableWSL": $API_OK,
    "QuicReachableWSL": $QUIC_OK,
    "WslEnvironmentOK": $WSL_OK,
    "Timestamp": "$(date -Iseconds)"
  }
}
EOF
