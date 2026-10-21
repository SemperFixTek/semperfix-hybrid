#!/usr/bin/env bash
set -euo pipefail

umask 002
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

# Safety: prevent CRLF issues
dos2unix "$0" 2>/dev/null || true

# Load Phoenix core + JSON helpers
source /opt/semperfix/scripts/phoenix-core.sh
source /opt/semperfix/scripts/phoenix-json.sh
phoenix_init

LOGFILE="${LOG_DIR}/mesh-handshake.log"
JSON_OUT="${STATE_DIR}/mesh-handshake.json"

PHOENIX_LOGFILE="$LOGFILE"
log() { phoenix_log_file "INFO" "$*"; }

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

    local handshake_status="fail"

    case "$NODE_ROLE" in

        MASTERZERO-ACTIVE|MASTERZERO-DEGRADED|MASTERZERO-RECOVER)
            log "${NODE_ROLE} initiating full mesh handshake"
            check_syncthing_api
            check_quic
            dump_peers
            handshake_status="pass"
            ;;

        SECONDARY-ACTIVE)
            log "SECONDARY-ACTIVE performing controller-side handshake"
            check_syncthing_api
            check_quic
            dump_peers
            handshake_status="pass"
            ;;

        SECONDARY-PASSIVE)
            log "SECONDARY-PASSIVE performing responder-side diagnostics"
            check_syncthing_api
            dump_peers
            json_set "$JSON_OUT" "quic_status" "handled_by_responder"
            handshake_status="pass"
            ;;

        OFFSITE)
            log "OFFSITE performing observer-only handshake"
            check_syncthing_api
            json_set "$JSON_OUT" "quic_status" "not_applicable"
            json_set_raw "$JSON_OUT" "peer_dump" "null"
            handshake_status="pass"
            ;;

        *)
            log "Unknown node role: ${NODE_ROLE}"
            json_set "$JSON_OUT" "error" "invalid_node_role"
            handshake_status="fail"
            ;;
    esac

    json_set "$JSON_OUT" "handshake_status" "$handshake_status"

    log "Handshake diagnostics complete"
    json_finalize "$JSON_OUT"

    /opt/semperfix/scripts/json-perms.sh "$JSON_OUT"
}

main "$@"
