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

HEARTBEAT_FILE="${STATE_DIR}/phoenix-heartbeat.json"
LOGFILE="${LOG_DIR}/phoenix-heartbeat.log"

mkdir -p "$STATE_DIR" "$LOG_DIR"

log() {
    echo "[INFO] $1" | tee -a "$LOGFILE"
}

# ---------- Health Checks ----------
check_api() {
    curl -s -o /dev/null -w "%{http_code}" \
        -H "X-API-Key: $API_KEY" \
        "$API_URL/system/status" 2>/dev/null
}

check_syncthing_ready() {
    curl -s -H "X-API-Key: $API_KEY" "$API_URL/system/status" \
        | jq -r '.myID != null' 2>/dev/null
}

check_peer_connected() {
    jq -r '.connections | length > 0' "${LOG_DIR}/mesh-handshake.json" 2>/dev/null
}

check_quic() {
    echo "probe" | nc -u -w1 -q1 "$PEER_IP" "$PHOENIX_QUIC_PORT" 2>/dev/null
}

check_mesh_ok() {
    jq -r '
        (.handshake_status == "pass")
        and (.verify_status == "pass")
        and (.activate_status == "pass")
    ' "${STATE_DIR}/phoenix-supervisor.json" 2>/dev/null
}

main() {
    : > "$LOGFILE"
    log "Starting Phoenix v2 Heartbeat for role: ${NODE_ROLE}"

    # Default values
    local api_ok="false"
    local peer_connected="not_applicable"
    local syncthing_ready="false"
    local quic_ok="not_applicable"
    local mesh_ok="not_applicable"

    # Always check API + readiness
    api_ok=$(check_api || echo "false")
    [[ "$api_ok" == "200" ]] && api_ok="true" || api_ok="false"

    syncthing_ready=$(check_syncthing_ready || echo "false")

    case "$NODE_ROLE" in

        MASTERZERO|SECONDARY)
            # These nodes participate fully in the mesh
            peer_connected=$(check_peer_connected || echo "false")

            local quic_probe
            quic_probe=$(check_quic || echo "")
            [[ -n "$quic_probe" ]] && quic_ok="true" || quic_ok="false"

            mesh_ok=$(check_mesh_ok || echo "false")
            ;;

        OFFSITE)
            log "INFO" "OFFSITE heartbeat: limited checks only"
            # peer_connected, quic_ok, mesh_ok remain "not_applicable"
            ;;

        *)
            log "INFO" "Unknown node role: ${NODE_ROLE}"
            ;;
    esac

    # ---------- Unified JSON Writer ----------
    json_init "$HEARTBEAT_FILE"

    json_set "$HEARTBEAT_FILE" "timestamp" "$(date -Iseconds)"
    json_set "$HEARTBEAT_FILE" "node_role" "$NODE_ROLE"
    json_set "$HEARTBEAT_FILE" "api_ok" "$api_ok"
    json_set "$HEARTBEAT_FILE" "peer_connected" "$peer_connected"
    json_set "$HEARTBEAT_FILE" "syncthing_ready" "$syncthing_ready"
    json_set "$HEARTBEAT_FILE" "quic_ok" "$quic_ok"
    json_set "$HEARTBEAT_FILE" "mesh_ok" "$mesh_ok"

    json_finalize "$HEARTBEAT_FILE"

    log "Heartbeat written to $HEARTBEAT_FILE"
}


main "$@"
