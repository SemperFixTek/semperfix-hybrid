#!/usr/bin/env bash
set -euo pipefail

source /opt/semperfix/scripts/phoenix-core.sh
source /opt/semperfix/scripts/phoenix-json.sh
phoenix_load_config

# ---------- Color Codes ----------
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
NC="\033[0m"

log() {
    local level="$1"
    local msg="$2"
    local color="$3"

    echo -e "${color}[${level}]${NC} ${msg}"
    echo "[${level}] ${msg}" >> "$LOGFILE"
}

LOGFILE="/opt/semperfix/logs/mesh-activate.log"
JSON_OUT="/opt/semperfix/logs/mesh-activate.json"

# ... colors + log() unchanged ...

check_readiness() {
    local api_url="$1"
    local api_key="$2"

    log "INFO" "Checking Syncthing readiness" "$BLUE"

    local status
    status=$(curl -s -H "X-API-Key: ${api_key}" "${api_url}/system/status")

    echo "$status" >> "$LOGFILE"

    if [[ "$status" == *"majorSyncing\": false"* ]]; then
        log "PASS" "Syncthing ready for activation" "$GREEN"
        json_add "$JSON_OUT" "syncthing_ready" "true"
        return 0
    else
        log "WARN" "Syncthing still syncing" "$YELLOW"
        json_add "$JSON_OUT" "syncthing_ready" "false"
        return 0
    fi
}

activate_quic() {
    local target_ip="$1"
    local target_port="$2"

    log "INFO" "Attempting QUIC activation to ${target_ip}:${target_port}" "$BLUE"

    if echo "activate" | nc -u -w1 "${target_ip}" "${target_port}" &>/dev/null; then
        log "PASS" "QUIC activation packet sent" "$GREEN"
        json_add "$JSON_OUT" "quic_activation" "sent"
        return 0
    else
        log "FAIL" "QUIC activation failed" "$RED"
        json_add "$JSON_OUT" "quic_activation" "failed"
        return 0
    fi
}

verify_peer_after_activation() {
    local api_url="$1"
    local api_key="$2"

    log "INFO" "Rechecking peer connectivity after activation" "$BLUE"

    local matrix
    matrix=$(curl -s -H "X-API-Key: ${api_key}" "${api_url}/system/connections")

    echo "$matrix" >> "$LOGFILE"

    if [[ "$matrix" == *"connected\": true"* ]]; then
        log "PASS" "Peer connected after activation" "$GREEN"
        json_add "$JSON_OUT" "peer_connected_after_activation" "true"
        return 0
    else
        log "FAIL" "Peer still disconnected after activation" "$RED"
        json_add "$JSON_OUT" "peer_connected_after_activation" "false"
        return 0
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

    check_readiness "$API_URL" "$API_KEY"
    activate_quic "$PEER_IP" "$PEER_PORT"
    verify_peer_after_activation "$API_URL" "$API_KEY"

    log "INFO" "Mesh activation complete" "$GREEN"
    json_close "$JSON_OUT"
}

main "$@"
