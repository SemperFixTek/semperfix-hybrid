#!/usr/bin/env bash
set -euo pipefail

STATUS="/opt/semperfix/state/mesh-status.json"
OUT="/opt/semperfix/state/mesh-status-validate.json"
LOG="/opt/semperfix/logs/mesh-status-validate.log"

RED="\033[0;31m"; GREEN="\033[0;32m"; YELLOW="\033[1;33m"; BLUE="\033[0;34m"; NC="\033[0m"

log() {
    echo -e "${3}[${1}]${NC} ${2}"
    echo "[${1}] ${2}" >> "$LOG"
}

json_init() { echo "{" > "$OUT"; }
json_add() {
    local key="$1"
    local value="$2"
    value=$(printf '%s' "$value" | jq -Rsa .)
    value="${value:1:${#value}-2}"
    echo "  \"${key}\": \"${value}\"," >> "$OUT"
}
json_close() {
    sed -i '$ s/,$//' "$OUT"
    echo "}" >> "$OUT"
}

main() {
    mkdir -p /opt/semperfix/state
    mkdir -p /opt/semperfix/logs
    : > "$LOG"

    log "INFO" "Mesh Status Validate (Phoenix v2)" "$BLUE"

    json_init
    json_add "timestamp" "$(date -Iseconds)"

    if [[ ! -f "$STATUS" ]]; then
        log "FAIL" "mesh-status.json missing" "$RED"
        json_add "valid" "false"
        json_add "reason" "missing_status_file"
        json_close
        exit 0
    fi

    local mesh_ok api_ok peer_connected syncthing_ready quic_ok

    mesh_ok=$(jq -r '.mesh_ok' "$STATUS")
    api_ok=$(jq -r '.api_ok' "$STATUS")
    peer_connected=$(jq -r '.peer_connected' "$STATUS")
    syncthing_ready=$(jq -r '.syncthing_ready' "$STATUS")
    quic_ok=$(jq -r '.quic_ok' "$STATUS")

    if [[ "$mesh_ok" == "true" ]]; then
        json_add "valid" "true"
        json_add "reason" "mesh_healthy"
    else
        json_add "valid" "false"
        json_add "reason" "mesh_unhealthy"
    fi

    json_add "mesh_ok" "$mesh_ok"
    json_add "api_ok" "$api_ok"
    json_add "peer_connected" "$peer_connected"
    json_add "syncthing_ready" "$syncthing_ready"
    json_add "quic_ok" "$quic_ok"

    json_close
    log "INFO" "Mesh status validation written to $OUT" "$GREEN"
}

main "$@"
