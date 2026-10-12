#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="/var/lib/semperfix/state"
LOG_DIR="/opt/semperfix/logs"

mkdir -p "$STATE_DIR" "$LOG_DIR"
dos2unix "$0" 2>/dev/null || true

source /opt/semperfix/scripts/phoenix-core.sh
source /opt/semperfix/scripts/phoenix-json.sh
phoenix_init

LOGFILE="${LOG_DIR}/mesh-listener.log"
STATUS_JSON="${STATE_DIR}/mesh-status.json"

PHOENIX_LOGFILE="$LOGFILE"
log() { phoenix_log_file "INFO" "$*"; }

SYNCTHING_API="${API_URL}/system/status"
QUIC_IP="${PEER_IP}"
QUIC_PORT="${PEER_PORT}"

write_state() {
    json_init "$STATUS_JSON"
    json_set "$STATUS_JSON" "timestamp" "$(date -Iseconds)"
    json_set "$STATUS_JSON" "node_role" "$NODE_ROLE"
    json_set "$STATUS_JSON" "syncthing_reachable" "$1"
    json_set "$STATUS_JSON" "quic_reachable" "$2"
    json_finalize "$STATUS_JSON"
}

check_syncthing() {
    if curl -s --max-time 2 -H "X-API-Key: ${API_KEY}" "$SYNCTHING_API" >/dev/null; then
        echo "true"
    else
        echo "false"
    fi
}

check_quic() {
    # Proper UDP probe
    if echo "probe" | nc -u -w1 "${QUIC_IP}" "${QUIC_PORT}" &>/dev/null; then
        echo "true"
    else
        echo "false"
    fi
}

# Listener only runs on MASTERZERO
if [[ "$NODE_ROLE" != "MASTERZERO" ]]; then
    log "Mesh listener disabled for role: ${NODE_ROLE}"
    exit 0
fi

log "Phoenix Mesh Listener starting for role ${NODE_ROLE}"

while true; do
    syncthing_ok=$(check_syncthing)
    quic_ok=$(check_quic)

    log "Syncthing=${syncthing_ok}  QUIC=${quic_ok}"

    write_state "$syncthing_ok" "$quic_ok"

    sleep 5
done
