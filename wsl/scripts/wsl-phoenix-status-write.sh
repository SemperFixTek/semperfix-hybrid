#!/usr/bin/env bash
set -euo pipefail

# Phoenix v2 Standard Environment Header
umask 002

# Ensure consistent locale + predictable JSON behavior
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

# Ensure logs and state directories exist
mkdir -p /var/lib/semperfix/state
mkdir -p /opt/semperfix/logs

# Safety: prevent Windows CRLF issues
dos2unix "$0" 2>/dev/null || true


source /opt/semperfix/scripts/phoenix-core.sh
source /opt/semperfix/scripts/phoenix-json.sh
phoenix_load_config

STATE_DIR="/var/lib/semperfix/state"
LOG_DIR="/opt/semperfix/logs"

STATUS_FILE="${STATE_DIR}/phoenix-status.json"
HB_JSON="${STATE_DIR}/phoenix-heartbeat.json"
SUP_JSON="${STATE_DIR}/phoenix-supervisor.json"

mkdir -p "$STATE_DIR" "$LOG_DIR"

log() {
    echo "[INFO] $1"
}

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

    # ---------- Unified JSON Writer ----------
    json_init "$STATUS_FILE"

    # ----- meta -----
    json_set_raw "$STATUS_FILE" "meta" "$(jq -n \
        --arg ts "$timestamp" \
        '{version:"2.0", generated_by:"phoenix-status-write", timestamp:$ts}')"

    # ----- node -----
    json_set_raw "$STATUS_FILE" "node" "$(jq -n \
        --arg role "$NODE_ROLE" \
        --arg api "$API_URL" \
        --arg peer "${PEER_IP}:${PEER_PORT}" \
        '{role:$role, api_url:$api, peer_target:$peer}')"

    # ----- health -----
    json_set_raw "$STATUS_FILE" "health" "$(jq -n \
        --argjson api_ok "$api_ok" \
        --argjson peer_connected "$peer_connected" \
        --argjson syncthing_ready "$syncthing_ready" \
        --argjson quic_ok "$quic_ok" \
        --argjson mesh_ok "$mesh_ok" \
        '{api_ok:$api_ok, peer_connected:$peer_connected, syncthing_ready:$syncthing_ready, quic_ok:$quic_ok, mesh_ok:$mesh_ok}')"

    # ----- supervisor -----
    json_set_raw "$STATUS_FILE" "supervisor" "$(jq -n \
        --arg handshake "$(jq -r '.handshake // "unknown"' "$SUP_JSON")" \
        --arg verify "$(jq -r '.verify // "unknown"' "$SUP_JSON")" \
        --arg activate "$(jq -r '.activate // "unknown"' "$SUP_JSON")" \
        '{handshake:$handshake, verify:$verify, activate:$activate}')"

    json_finalize "$STATUS_FILE"

    log "Phoenix status written to $STATUS_FILE"
}

write_status
