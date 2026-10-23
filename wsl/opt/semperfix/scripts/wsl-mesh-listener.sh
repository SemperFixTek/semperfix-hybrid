#!/usr/bin/env bash
set -euo pipefail

umask 002
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

dos2unix "$0" 2>/dev/null || true

source /opt/semperfix/scripts/phoenix-core.sh
source /opt/semperfix/scripts/phoenix-json.sh
phoenix_init

LOGFILE="${LOG_DIR}/mesh-listener.log"
STATUS_JSON="${STATE_DIR}/mesh-listener.json"

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

    /opt/semperfix/scripts/json-perms.sh "$STATUS_JSON"
}

check_syncthing() {
    if curl -s --max-time 2 -H "X-API-Key: ${API_KEY}" "$SYNCTHING_API" >/dev/null; then
        echo "true"
    else
        echo "false"
    fi
}

check_quic() {
    if echo "probe" | nc -u -w1 "${QUIC_IP}" "${QUIC_PORT}" &>/dev/null; then
        echo "true"
    else
        echo "false"
    fi
}

# Phoenix v2.1 controller roles
case "$NODE_ROLE" in
    MASTERZERO-ACTIVE|MASTERZERO-DEGRADED|MASTERZERO-RECOVER|SECONDARY-ACTIVE)
        log "Phoenix Mesh Listener starting for controller role: ${NODE_ROLE}"
        ;;
    *)
        log "Mesh listener disabled for role: ${NODE_ROLE}"
        exit 0
        ;;
esac

while true; do
    syncthing_ok=$(check_syncthing)
    quic_ok=$(check_quic)

    log "Syncthing=${syncthing_ok}  QUIC=${quic_ok}"

    write_state "$syncthing_ok" "$quic_ok"

    sleep 5
done
