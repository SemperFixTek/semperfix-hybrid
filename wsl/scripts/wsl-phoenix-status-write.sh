#!/usr/bin/env bash
set -euo pipefail

source /opt/semperfix/scripts/phoenix-core.sh
phoenix_load_config

STATUS_FILE="/opt/semperfix/state/phoenix-status.json"

MS_JSON="/opt/semperfix/logs/mesh-status.json"
MH_JSON="/opt/semperfix/logs/mesh-handshake.json"
MA_JSON="/opt/semperfix/logs/mesh-activate.json"
SUP_JSON="/opt/semperfix/logs/phoenix-supervisor.json"

mkdir -p /opt/semperfix/state

safe_bool() {
    local file="$1"
    local field="$2"
    local val
    val=$(jq -r "$field // \"false\"" "$file" 2>/dev/null || echo "false")
    [[ "$val" == "true" ]] && echo "true" || echo "false"
}

write_status() {
    local timestamp
    timestamp=$(date -Iseconds)

    local api_ok peer_connected syncthing_ready quic_ok
    api_ok=$(safe_bool "$MS_JSON" '.api_ok')
    peer_connected=$(safe_bool "$MS_JSON" '.peer_connected')
    syncthing_ready=$(safe_bool "$MA_JSON" '.syncthing_ready')
    quic_ok=$(safe_bool "$MH_JSON" '.quic_status')

    cat > "$STATUS_FILE" <<EOF
{
  "meta": {
    "version": "2.0",
    "generated_by": "phoenix-status-write",
    "timestamp": "$timestamp"
  },
  "node": {
    "role": "$NODE_ROLE",
    "api_url": "$API_URL",
    "peer_target": "${PEER_IP}:${PEER_PORT}"
  },
  "health": {
    "api_ok": $api_ok,
    "peer_connected": $peer_connected,
    "syncthing_ready": $syncthing_ready,
    "quic_ok": $quic_ok,
    "mesh_ok": true
  },
  "supervisor": {
    "handshake": "$(jq -r '.handshake_status // "unknown"' "$SUP_JSON")",
    "verify": "$(jq -r '.verify_status // "unknown"' "$SUP_JSON")",
    "activate": "$(jq -r '.activate_status // "unknown"' "$SUP_JSON")"
  }
}
EOF
}

write_status
echo "[INFO] Phoenix status written to $STATUS_FILE"
