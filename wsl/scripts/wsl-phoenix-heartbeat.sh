#!/usr/bin/env bash
set -uo pipefail

source /opt/semperfix/scripts/phoenix-core.sh
phoenix_load_config

STATE_DIR="/var/lib/semperfix/state"
LOG_DIR="/opt/semperfix/logs"

HEARTBEAT_FILE="${STATE_DIR}/phoenix-heartbeat.json"
LOGFILE="${LOG_DIR}/phoenix-heartbeat.log"

mkdir -p "$STATE_DIR" "$LOG_DIR"

log() {
    echo "[INFO] $1" | tee -a "$LOGFILE"
}

json_init() {
    echo "{" > "$HEARTBEAT_FILE"
}

json_add() {
    local key="$1"
    local value="$2"

    value=$(printf '%s' "$value" | jq -Rsa .)
    value="${value:1:${#value}-2}"

    echo "  \"${key}\": \"${value}\"," >> "$HEARTBEAT_FILE"
}

json_close() {
    awk '
    NR == 1 { print; next }
    {
        if (prev ~ /,$/) sub(/,$/, "", prev)
        print prev
        prev = $0
    }
    END { print prev }
    ' "$HEARTBEAT_FILE" > "${HEARTBEAT_FILE}.tmp"

    mv "${HEARTBEAT_FILE}.tmp" "$HEARTBEAT_FILE"
}

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
    echo "probe" | nc -u -w1 -q1 "$PEER_IP" "$PEER_PORT" 2>/dev/null
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
    log "Starting Phoenix v2 Heartbeat"

    local api_ok peer_connected syncthing_ready quic_ok mesh_ok

    api_ok=$(check_api || echo "false")
    [[ "$api_ok" == "200" ]] && api_ok="true" || api_ok="false"

    peer_connected=$(check_peer_connected || echo "false")
    syncthing_ready=$(check_syncthing_ready || echo "false")

    quic_ok=$(check_quic || echo "")
    [[ -n "$quic_ok" ]] && quic_ok="true" || quic_ok="false"

    mesh_ok=$(check_mesh_ok || echo "false")

    json_init
    json_add "timestamp" "$(date -Iseconds)"
    json_add "api_ok" "$api_ok"
    json_add "peer_connected" "$peer_connected"
    json_add "syncthing_ready" "$syncthing_ready"
    json_add "quic_ok" "$quic_ok"
    json_add "mesh_ok" "$mesh_ok"
    json_close

    log "Heartbeat written to $HEARTBEAT_FILE"
}

main "$@"
