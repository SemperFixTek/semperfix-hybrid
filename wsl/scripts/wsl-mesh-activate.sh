#!/usr/bin/env bash
set -euo pipefail

source /opt/semperfix/scripts/phoenix-core.sh
source /opt/semperfix/scripts/phoenix-json.sh
phoenix_load_config

LOGFILE="/opt/semperfix/logs/mesh-activate.log"
JSON_OUT="/opt/semperfix/logs/mesh-activate.json"

RED="\033[0;31m"; GREEN="\033[0;32m"; YELLOW="\033[1;33m"; BLUE="\033[0;34m"; NC="\033[0m"

log() {
    echo -e "${3}[${1}]${NC} ${2}"
    echo "[${1}] ${2}" >> "$LOGFILE"
}

check_readiness() {
    log "INFO" "Checking Syncthing readiness" "$BLUE"
    local status
    status=$(curl -s -H "X-API-Key: $API_KEY" "$API_URL/system/status")
    echo "$status" >> "$LOGFILE"

    if [[ "$status" == *"majorSyncing\": false"* ]]; then
        log "PASS" "Syncthing ready for activation" "$GREEN"
        json_add "$JSON_OUT" "syncthing_ready" "true"
    else
        log "WARN" "Syncthing still syncing" "$YELLOW"
        json_add "$JSON_OUT" "syncthing_ready" "false"
    fi
}

activate_quic() {
    log "INFO" "Attempting QUIC activation to $PEER_IP:$PEER_PORT" "$BLUE"
    if echo "activate" | nc -u -w1 "$PEER_IP" "$PEER_PORT" &>/dev/null; then
        log "PASS" "QUIC activation packet sent" "$GREEN"
        json_add "$JSON_OUT" "quic_activation" "sent"
    else
        log "FAIL" "QUIC activation failed" "$RED"
        json_add "$JSON_OUT" "quic_activation" "failed"
    fi
}

verify_peer_after_activation() {
    log "INFO" "Rechecking peer connectivity after activation" "$BLUE"
    local matrix
    matrix=$(curl -s -H "X-API-Key: $API_KEY" "$API_URL/system/connections")
    echo "$matrix" >> "$LOGFILE"

    if [[ "$matrix" == *"connected\": true"* ]]; then
        log "PASS" "Peer connected after activation" "$GREEN"
        json_add "$JSON_OUT" "peer_connected_after_activation" "true"
    else
        log "FAIL" "Peer still disconnected after activation" "$RED"
        json_add "$JSON_OUT" "peer_connected_after_activation" "false"
    fi
}

main() {
    mkdir -p /opt/semperfix/logs
    : > "$LOGFILE"

    json_init "$JSON_OUT"
    log "INFO" "Starting Phoenix Mesh Activation" "$YELLOW"

    json_add "$JSON_OUT" "timestamp" "$(date -Iseconds)"
    json_add "$JSON_OUT" "node_role" "$NODE_ROLE"
    json_add "$JSON_OUT" "api_url" "$API_URL"
    json_add "$JSON_OUT" "peer_target" "${PEER_IP}:${PEER_PORT}"

    check_readiness
    activate_quic
    verify_peer_after_activation

    log "INFO" "Mesh activation complete" "$GREEN"
    json_close "$JSON_OUT"
}

main "$@"
