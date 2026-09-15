#!/usr/bin/env bash
set -euo pipefail

STATUS_FILE="/opt/semperfix/state/phoenix-status.json"
HEARTBEAT_FILE="/opt/semperfix/state/phoenix-heartbeat.json"
LOGFILE="/opt/semperfix/logs/phoenix-heartbeat.log"

RED="\033[0;31m"; GREEN="\033[0;32m"; YELLOW="\033[1;33m"; BLUE="\033[0;34m"; NC="\033[0m"

log() {
    echo -e "${3}[${1}]${NC} ${2}"
    echo "[${1}] ${2}" >> "$LOGFILE"
}

json_init() { echo "{" > "$HEARTBEAT_FILE"; }
json_add() {
    local key="$1"
    local value="$2"
    value=$(printf '%s' "$value" | jq -Rsa .)
    value="${value:1:${#value}-2}"
    echo "  \"${key}\": \"${value}\"," >> "$HEARTBEAT_FILE"
}
json_close() {
    sed -i '$ s/,$//' "$HEARTBEAT_FILE"
    echo "}" >> "$HEARTBEAT_FILE"
}

main() {
    mkdir -p /opt/semperfix/state
    mkdir -p /opt/semperfix/logs
    : > "$LOGFILE"

    log "INFO" "Starting Phoenix v2 Heartbeat" "$BLUE"

    if [[ ! -f "$STATUS_FILE" ]]; then
        log "FAIL" "Status file missing" "$RED"
        exit 0
    fi

    json_init
    json_add "timestamp" "$(date -Iseconds)"
    json_add "api_ok" "$(jq -r '.health.api_ok' "$STATUS_FILE")"
    json_add "peer_connected" "$(jq -r '.health.peer_connected' "$STATUS_FILE")"
    json_add "syncthing_ready" "$(jq -r '.health.syncthing_ready' "$STATUS_FILE")"
    json_add "quic_ok" "$(jq -r '.health.quic_ok' "$STATUS_FILE")"
    json_add "mesh_ok" "$(jq -r '.health.mesh_ok' "$STATUS_FILE")"
    json_close

    log "INFO" "Heartbeat written to $HEARTBEAT_FILE" "$GREEN"
}

main "$@"
