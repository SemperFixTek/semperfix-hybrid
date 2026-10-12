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

LOGFILE="${LOG_DIR}/mesh-handshake.log"
JSON_OUT="${STATE_DIR}/mesh-handshake.json"

# Use core logging
PHOENIX_LOGFILE="$LOGFILE"
log() { phoenix_log_file "INFO" "$*"; }

RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
NC="\033[0m"

check_quic() {
    log "Checking QUIC reachability to ${PEER_IP}:${PEER_PORT}"
    if nc -zvu "${PEER_IP}" "${PEER_PORT}" &>/dev/null; then
        log "QUIC reachable"
        json_set "$JSON_OUT" "quic_status" "reachable"
        return 0
    else
        log "QUIC unreachable"
        json_set "$JSON_OUT" "quic_status" "unreachable"
        return 1
    fi
}

check_syncthing_api() {
    log "Checking Syncthing API at ${API_URL}"
    local status
    status=$(curl -s -H "X-API-Key: ${API_KEY}" "${API_URL}/system/ping" || echo "error")

    if [[ "$status" == *"pong"* ]]; then
        log "Syncthing API reachable"
        json_set "$JSON_OUT" "syncthing_api" "reachable"
        return 0
    else
        log "Syncthing API unreachable"
        json_set "$JSON_OUT" "syncthing_api" "unreachable"
        return 1
    fi
}

dump_peers() {
    log "Dumping peer list"
    local peers
    peers=$(curl -s -H "X-API-Key: ${API_KEY}" "${API_URL}/system/connections")
    json_set_raw "$JSON_OUT" "peer_dump" "$peers"
}

main() {
    log "Starting Phoenix Mesh Handshake for role: ${NODE_ROLE}"

    json_init "$JSON_OUT"
    json_set "$JSON_OUT" "timestamp" "$(date -Iseconds)"
    json_set "$JSON_OUT" "node_role" "$NODE_ROLE"
    json_set "$JSON_OUT" "api_url" "$API_URL"
    json_set "$JSON_OUT" "peer_target" "${PEER_IP}:${PEER_PORT}"

    case "$NODE_ROLE" in

        MASTERZERO)
            log "MASTERZERO initiating full mesh handshake"
            check_syncthing_api
            check_quic
            dump_peers
            ;;

        SECONDARY)
            log "SECONDARY performing responder-side diagnostics"
            check_syncthing_api
            dump_peers
            json_set "$JSON_OUT" "quic_status" "handled_by_responder"
            ;;

        OFFSITE)
            log "OFFSITE performing observer-only handshake"
            check_syncthing_api
            json_set "$JSON_OUT" "quic_status" "not_applicable"
            json_set "$JSON_OUT" "peer_dump" "not_applicable"
            ;;

        *)
            log "Unknown node role: ${NODE_ROLE}"
            json_set "$JSON_OUT" "error" "invalid_node_role"
            ;;
    esac

    log "Handshake diagnostics complete"
    json_finalize "$JSON_OUT"
}

main "$@"
