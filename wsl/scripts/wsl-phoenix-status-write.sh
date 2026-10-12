#!/usr/bin/env bash
set -euo pipefail

umask 002
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

STATE_DIR="/var/lib/semperfix/state"
LOG_DIR="/opt/semperfix/logs"

mkdir -p "$STATE_DIR" "$LOG_DIR"
dos2unix "$0" 2>/dev/null || true

source /opt/semperfix/scripts/phoenix-core.sh
source /opt/semperfix/scripts/phoenix-json.sh
phoenix_init

STATUS_FILE="${STATE_DIR}/phoenix-status.json"
HB_JSON="${STATE_DIR}/phoenix-heartbeat.json"
SUP_JSON="${STATE_DIR}/phoenix-supervisor.json"

PHOENIX_LOGFILE="${LOG_DIR}/phoenix-status.log"
log() { phoenix_log_file "INFO" "$*"; }

safe_field() {
    local file="$1"
    local field="$2"
    local val

    val=$(jq -r "$field // \"not_applicable\"" "$file" 2>/dev/null || echo "not_applicable")

    case "$val" in
        true|false|not_applicable) echo "$val" ;;
        *) echo "not_applicable" ;;
    esac
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
    api_ok=$(safe_field "$HB_JSON" '.api_ok')
    peer_connected=$(safe_field "$HB_JSON" '.peer_connected')
    syncthing_ready=$(safe_field "$HB_JSON" '.syncthing_ready')
    quic_ok=$(safe_field "$HB_JSON" '.quic_ok')
    mesh_ok=$(check_mesh_ok)

    json_init "$STATUS_FILE"

    json_set_raw "$STATUS_FILE" "meta" "$(jq -n \
        --arg ts "$timestamp" \
        '{version:"2.0", generated_by:"phoenix-status-write", timestamp:$ts}')"

    json_set_raw "$STATUS_FILE" "node" "$(jq -n \
        --arg role "$NODE_ROLE" \
        --arg api "$API_URL" \
        --arg peer "${PEER_IP}:${PEER_PORT}" \
        '{role:$role, api_url:$api, peer_target:$peer}')"

    json_set_raw "$STATUS_FILE" "health" "$(jq -n \
        --arg api_ok "$api_ok" \
        --arg peer_connected "$peer_connected" \
        --arg syncthing_ready "$syncthing_ready" \
        --arg quic_ok "$quic_ok" \
        --arg mesh_ok "$mesh_ok" \
        '{api_ok:$api_ok, peer_connected:$peer_connected, syncthing_ready:$syncthing_ready, quic_ok:$quic_ok, mesh_ok:$mesh_ok}')"

    json_set_raw "$STATUS_FILE" "supervisor" "$(jq -n \
        --arg handshake "$(jq -r '.handshake // "unknown"' "$SUP_JSON")" \
        --arg verify "$(jq -r '.verify // "unknown"' "$SUP_JSON")" \
        --arg activate "$(jq -r '.activate // "unknown"' "$SUP_JSON")" \
        '{handshake:$handshake, verify:$verify, activate:$activate}')"

    json_finalize "$STATUS_FILE"

    log "Phoenix status written to $STATUS_FILE"
}

write_status
