#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Phoenix Mesh Status — SemperFix Edition (v2)
# ============================================================

source /opt/semperfix/scripts/phoenix-core.sh
phoenix_load_config

STATUS_LOG="/opt/semperfix/logs/mesh-status.log"
STATUS_JSON="/opt/semperfix/logs/mesh-status.json"

RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
NC="\033[0m"

log() {
    echo -e "${3}[${1}]${NC} ${2}"
    echo "[${1}] ${2}" >> "$STATUS_LOG"
}

json_init() { echo "{" > "$STATUS_JSON"; }
json_add() { echo "  \"$1\": \"$2\"," >> "$STATUS_JSON"; }
json_close() {
    sed -i '$ s/,$//' "$STATUS_JSON"
    echo "}" >> "$STATUS_JSON"
}

check_api() {
    local pong
    pong=$(curl -s -H "X-API-Key: ${API_KEY}" "${API_URL}/system/ping" || echo "error")

    if [[ "$pong" == *"pong"* ]]; then
        log "PASS" "Syncthing API reachable" "$GREEN"
        json_add "api_ok" "true"
    else
        log "FAIL" "Syncthing API unreachable" "$RED"
        json_add "api_ok" "false"
    fi
}

check_connections() {
    local matrix
    matrix=$(curl -s -H "X-API-Key: ${API_KEY}" "${API_URL}/system/connections")

    echo "$matrix" >> "$STATUS_LOG"

    if [[ "$matrix" == *"connected\": true"* ]]; then
        log "PASS" "Peer connected" "$GREEN"
        json_add "peer_connected" "true"
    else
        log "FAIL" "Peer disconnected" "$RED"
        json_add "peer_connected" "false"
    fi
}

main() {
    mkdir -p /opt/semperfix/logs
    : > "$STATUS_LOG"

    json_init

    log "INFO" "Phoenix Mesh Status (v2)" "$YELLOW"
    json_add "timestamp" "$(date -Iseconds)"
    json_add "node_role" "$NODE_ROLE"

    check_api
    check_connections

    log "INFO" "Mesh status complete" "$GREEN"
    json_close
}

main "$@"
