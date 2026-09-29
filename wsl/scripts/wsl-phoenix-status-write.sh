#!/usr/bin/env bash
set -euo pipefail

source /opt/semperfix/scripts/phoenix-core.sh
phoenix_load_config

STATE_DIR="/var/lib/semperfix/state"
LOG_DIR="/opt/semperfix/logs"

STATUS_FILE="${STATE_DIR}/phoenix-status.json"
HB_JSON="${STATE_DIR}/phoenix-heartbeat.json"
SUP_JSON="${STATE_DIR}/phoenix-supervisor.json"

mkdir -p "$STATE_DIR"

safe_bool() {
    local file="$1"
    local field="$2"
    local val

    val=$(jq -r "$field // \"false\"" "$file" 2>/dev/null || echo "false")
    [[ "$val" == "true" ]] && echo "true" || echo "false"
}

check_mesh_ok() {
    jq -r '
        (.handshake_status == "pass")
        and (.verify_status == "pass")
        and (.activate_status == "pass")
    ' "$SUP_JSON" 2>/dev/null | grep -q "true" && echo "true" || echo "false"
}

write_status() {
    local timestamp
    timestamp=$(date -Iseconds)

    local api_ok peer_connected syncthing_ready quic_ok mesh_ok
    api_ok=$(safe_bool "$HB_JSON" '.api_ok')
    peer_connected=$(safe_bool "$HB_JSON" '.peer_connected')
    syncthing_ready=$(safe_bool "$HB_JSON" '.syncthing_ready')
    quic_ok=$(safe_bool "$HB_JSON" '.quic_ok')
    mesh_ok=$(check_mesh_ok)

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
    "mesh_ok": $mesh_ok
  },
  "supervisor": {
    "handshake": "$(jq -r '.handshake // "unknown"' "$SUP_JSON" 2>/dev/null)",
    "verify": "$(jq -r '.verify // "unknown"' "$SUP_JSON" 2>/dev/null)",
    "activate": "$(jq -r '.activate // "unknown"' "$SUP_JSON" 2>/dev/null)"
  }
}
EOF
}

write_status
echo "[INFO] Phoenix status written to $STATUS_FILE"
