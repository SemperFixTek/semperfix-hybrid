#!/usr/bin/env bash
set -euo pipefail

SUPERVISOR="/opt/semperfix/logs/phoenix-supervisor.json"
STATUS="/opt/semperfix/state/phoenix-status.json"
HEARTBEAT="/opt/semperfix/state/phoenix-heartbeat.json"
OUT="/opt/semperfix/state/mesh-status.json"
LOG="/opt/semperfix/logs/mesh-status.log"

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

    log "INFO" "Mesh Status (Phoenix v2)" "$BLUE"

    json_init
    json_add "timestamp" "$(date -Iseconds)"

    if [[ -f "$SUPERVISOR" ]]; then
        json_add "handshake" "$(jq -r '.handshake_status' "$SUPERVISOR")"
        json_add "verify" "$(jq -r '.verify_status' "$SUPERVISOR")"
        json_add "activate" "$(jq -r '.activate_status' "$SUPERVISOR")"
    else
        json_add "handshake" "unknown"
        json_add "verify" "unknown"
        json_add "activate" "unknown"
    fi

    if [[ -f "$STATUS" ]]; then
        json_add "mesh_ok" "$(jq -r '.mesh_ok' "$STATUS")"
        json_add "node_role" "$(jq -r '.node_role' "$STATUS")"
        json_add "peer_target" "$(jq -r '.peer_target' "$STATUS")"
    else
        json_add "mesh_ok" "false"
        json_add "node_role" "unknown"
        json_add "peer_target" "unknown"
    fi

    if [[ -f "$HEARTBEAT" ]]; then
        json_add "api_ok" "$(jq -r '.api_ok' "$HEARTBEAT")"
        json_add "peer_connected" "$(jq -r '.peer_connected' "$HEARTBEAT")"
        json_add "syncthing_ready" "$(jq -r '.syncthing_ready' "$HEARTBEAT")"
        json_add "quic_ok" "$(jq -r '.quic_ok' "$HEARTBEAT")"
    else
        json_add "api_ok" "false"
        json_add "peer_connected" "false"
        json_add "syncthing_ready" "false"
        json_add "quic_ok" "false"
    fi

    json_close
    log "INFO" "Mesh status written to $OUT" "$GREEN"
}

main "$@"
