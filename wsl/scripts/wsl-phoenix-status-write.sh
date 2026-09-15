#!/usr/bin/env bash
set -euo pipefail

STATUS_FILE="/opt/semperfix/logs/phoenix-supervisor.json"
OUT_FILE="/opt/semperfix/state/phoenix-status.json"
LOGFILE="/opt/semperfix/logs/phoenix-status-write.log"

RED="\033[0;31m"; GREEN="\033[0;32m"; YELLOW="\033[1;33m"; BLUE="\033[0;34m"; NC="\033[0m"

log() {
    echo -e "${3}[${1}]${NC} ${2}"
    echo "[${1}] ${2}" >> "$LOGFILE"
}

json_init() { echo "{" > "$OUT_FILE"; }
json_add() {
    local key="$1"
    local value="$2"
    value=$(printf '%s' "$value" | jq -Rsa .)
    value="${value:1:${#value}-2}"
    echo "  \"${key}\": \"${value}\"," >> "$OUT_FILE"
}
json_close() {
    sed -i '$ s/,$//' "$OUT_FILE"
    echo "}" >> "$OUT_FILE"
}

main() {
    mkdir -p /opt/semperfix/state
    mkdir -p /opt/semperfix/logs
    : > "$LOGFILE"

    log "INFO" "Phoenix Status Write (v2)" "$BLUE"

    if [[ ! -f "$STATUS_FILE" ]]; then
        log "FAIL" "Supervisor JSON missing" "$RED"
        exit 0
    fi

    local handshake verify activate
    handshake=$(jq -r '.handshake_status' "$STATUS_FILE")
    verify=$(jq -r '.verify_status' "$STATUS_FILE")
    activate=$(jq -r '.activate_status' "$STATUS_FILE")

    local mesh_ok="false"
    if [[ "$handshake" == "pass" && "$verify" == "pass" && "$activate" == "pass" ]]; then
        mesh_ok="true"
    fi

    json_init
    json_add "timestamp" "$(date -Iseconds)"
    json_add "node_role" "$(jq -r '.node_role' "$STATUS_FILE")"
    json_add "api_url" "$(jq -r '.api_url' "$STATUS_FILE")"
    json_add "peer_target" "$(jq -r '.peer_target' "$STATUS_FILE")"

    json_add "mesh_ok" "$mesh_ok"
    json_add "handshake" "$handshake"
    json_add "verify" "$verify"
    json_add "activate" "$activate"

    json_close

    log "INFO" "Phoenix status written to $OUT_FILE" "$GREEN"
}

main "$@"
