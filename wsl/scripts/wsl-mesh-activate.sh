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

LOGFILE="${LOG_DIR}/mesh-activate.log"
JSON_OUT="${STATE_DIR}/mesh-activate.json"

PHOENIX_LOGFILE="$LOGFILE"
log() { phoenix_log_file "INFO" "$*"; }

check_readiness() {
    log "Checking Syncthing readiness"

    local status
    status=$(curl -s -H "X-API-Key: ${API_KEY}" "${API_URL}/system/status")

    printf "%s\n" "$status" >> "$LOGFILE"

    if echo "$status" | jq -e '.majorSyncing == false' >/dev/null 2>&1; then
        log "Syncthing ready for activation"
        json_set "$JSON_OUT" "syncthing_ready" "true"
        return 0
    else
        log "Syncthing still syncing"
        json_set "$JSON_OUT" "syncthing_ready" "false"
        return 1
    fi
}

activate_quic() {
    log "Attempting QUIC activation to ${PEER_IP}:${PEER_PORT}"

    if echo "activate" | nc -u -w1 "${PEER_IP}" "${PEER_PORT}" &>/dev/null; then
        log "QUIC activation packet sent"
        json_set "$JSON_OUT" "quic_activation" "sent"
        return 0
    else
        log "QUIC activation failed"
        json_set "$JSON_OUT" "quic_activation" "failed"
        return 1
    fi
}

verify_peer_after_activation() {
    log "Rechecking peer connectivity after activation"

    local matrix
    matrix=$(curl -s -H "X-API-Key: ${API_KEY}" "${API_URL}/system/connections")

    printf "%s\n" "$matrix" >> "$LOGFILE"

    if [[ "$matrix" == *"connected\": true"* ]]; then
        log "Peer connected after activation"
        json_set "$JSON_OUT" "peer_connected_after_activation" "true"
        return 0
    else
        log "Peer still disconnected after activation"
        json_set "$JSON_OUT" "peer_connected_after_activation" "false"
        return 1
    fi
}

main() {
    log "Starting Phoenix Mesh Activation for role: ${NODE_ROLE}"

    json_init "$JSON_OUT"
    json_set "$JSON_OUT" "timestamp" "$(date -Iseconds)"
    json_set "$JSON_OUT" "node_role" "$NODE_ROLE"
    json_set "$JSON_OUT" "api_url" "$API_URL"
    json_set "$JSON_OUT" "peer_target" "${PEER_IP}:${PEER_PORT}"

    case "$NODE_ROLE" in

        MASTERZERO)
            log "MASTERZERO performing full mesh activation"

            check_readiness
            activate_quic
            verify_peer_after_activation
            ;;

        SECONDARY)
            log "SECONDARY performing responder-side activation diagnostics"

            check_readiness

            json_set "$JSON_OUT" "quic_activation" "handled_by_responder"
            json_set "$JSON_OUT" "peer_connected_after_activation" "handled_by_responder"
            ;;

        OFFSITE)
            log "OFFSITE performing observer-only activation"

            check_readiness

            json_set "$JSON_OUT" "quic_activation" "not_applicable"
            json_set "$JSON_OUT" "peer_connected_after_activation" "not_applicable"
            ;;

        *)
            log "Unknown node role: ${NODE_ROLE}"
            json_set "$JSON_OUT" "error" "invalid_node_role"
            ;;
    esac

    log "Mesh activation complete"
    json_finalize "$JSON_OUT"
}

main "$@"
