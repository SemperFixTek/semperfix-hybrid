#!/usr/bin/env bash
set -euo pipefail

# Phoenix v2 Standard Environment Header
umask 002

# Ensure consistent locale + predictable JSON behavior
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

# Ensure logs and state directories exist
mkdir -p /var/lib/semperfix/state
mkdir -p /opt/semperfix/logs

# Safety: prevent Windows CRLF issues
dos2unix "$0" 2>/dev/null || true


# ============================================================
# Phoenix Mesh Status — SemperFix Edition (v2)
# ============================================================

source /opt/semperfix/scripts/phoenix-core.sh
source /opt/semperfix/scripts/phoenix-json.sh
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

check_api() {
    local pong
    pong=$(curl -s -H "X-API-Key: ${API_KEY}" "${API_URL}/system/ping" || echo "error")

    if [[ "$pong" == *"pong"* ]]; then
        log "PASS" "Syncthing API reachable" "$GREEN"
        json_set "$STATUS_JSON" "api_ok" "true"
    else
        log "FAIL" "Syncthing API unreachable" "$RED"
        json_set "$STATUS_JSON" "api_ok" "false"
    fi
}

check_connections() {
    local matrix
    matrix=$(curl -s -H "X-API-Key: ${API_KEY}" "${API_URL}/system/connections")

    echo "$matrix" >> "$STATUS_LOG"

    if [[ "$matrix" == *"connected\": true"* ]]; then
        log "PASS" "Peer connected" "$GREEN"
        json_set "$STATUS_JSON" "peer_connected" "true"
    else
        log "FAIL" "Peer disconnected" "$RED"
        json_set "$STATUS_JSON" "peer_connected" "false"
    fi
}

main() {
    mkdir -p /opt/semperfix/logs
    : > "$STATUS_LOG"

    json_init "$STATUS_JSON"

    log "INFO" "Phoenix Mesh Status (v2)" "$YELLOW"
    json_set "$STATUS_JSON" "timestamp" "$(date -Iseconds)"
    json_set "$STATUS_JSON" "node_role" "$NODE_ROLE"

    check_api
    check_connections

    log "INFO" "Mesh status complete" "$GREEN"
    json_finalize "$STATUS_JSON"
}

main "$@"
