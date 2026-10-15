#!/usr/bin/env bash
set -euo pipefail

umask 002
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

# Normalize line endings
dos2unix "$0" 2>/dev/null || true

# Load Phoenix core + JSON utilities
source /opt/semperfix/scripts/phoenix-core.sh
source /opt/semperfix/scripts/phoenix-json.sh
phoenix_init

STATUS_LOG="${LOG_DIR}/mesh-status.log"
STATUS_JSON="${STATE_DIR}/mesh-status.json"

PHOENIX_LOGFILE="$STATUS_LOG"
log() { phoenix_log_file "INFO" "$*"; }

check_api() {
    local pong
    pong=$(curl -s -H "X-API-Key: ${API_KEY}" "${API_URL}/system/ping" || echo "error")

    log "API ping result: ${pong}"

    if [[ "$pong" == *"pong"* ]]; then
        log "Syncthing API reachable"
        json_set "$STATUS_JSON" "api_ok" "true"
    else
        log "Syncthing API unreachable"
        json_set "$STATUS_JSON" "api_ok" "false"
    fi
}

check_connections() {
    local matrix
    matrix=$(curl -s -H "X-API-Key: ${API_KEY}" "${API_URL}/system/connections")

    printf "%s\n" "$matrix" >> "$STATUS_LOG"

    # Correct jq-based evaluation
    local connected
    connected=$(jq -r '.connections | length > 0' <<< "$matrix" 2>/dev/null || echo "false")

    if [[ "$connected" == "true" ]]; then
        log "Peer connected"
        json_set "$STATUS_JSON" "peer_connected" "true"
    else
        log "Peer disconnected"
        json_set "$STATUS_JSON" "peer_connected" "false"
    fi
}

main() {
    log "Phoenix Mesh Status (v2) — role: ${NODE_ROLE}"

    json_init "$STATUS_JSON"
    json_set "$STATUS_JSON" "timestamp" "$(date -Iseconds)"
    json_set "$STATUS_JSON" "node_role" "$NODE_ROLE"

    case "$NODE_ROLE" in

        MASTERZERO|SECONDARY)
            log "${NODE_ROLE} performing full mesh status check"
            check_api
            check_connections
            ;;

        OFFSITE)
            log "OFFSITE performing limited mesh status check"
            check_api
            json_set "$STATUS_JSON" "peer_connected" "not_applicable"
            ;;

        *)
            log "Unknown node role: ${NODE_ROLE}"
            json_set "$STATUS_JSON" "error" "invalid_node_role"
            ;;
    esac

    log "Mesh status complete"
    json_finalize "$STATUS_JSON"

    # Fix permissions for Syncthing + Windows
    /opt/semperfix/scripts/json-perms.sh "$STATUS_JSON"
}

main "$@"
