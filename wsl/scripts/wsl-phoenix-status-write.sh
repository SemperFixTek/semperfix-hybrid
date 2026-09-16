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

# Use shared JSON helpers from phoenix-json.sh
json_init() { json_init "$OUT_FILE"; }
json_add() { json_add "$OUT_FILE" "$1" "$2"; }
json_add_object_start() { json_add_object_start "$OUT_FILE" "$1"; }
json_add_object_end() { json_add_object_end "$OUT_FILE"; }

main() {
    mkdir -p /opt/semperfix/state
    mkdir -p /opt/semperfix/logs
    : > "$LOGFILE"

    log "INFO" "Phoenix Status Write (v2)" "$BLUE"

    if [[ ! -f "$STATUS_FILE" ]]; then
        log "FAIL" "Supervisor JSON missing at $STATUS_FILE" "$RED"
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

    # These are optional; if missing, they’ll be "null"
    local api_ok peer_connected syncthing_ready quic_ok
    api_ok=$(jq -r '.api_ok // "unknown"' "$STATUS_FILE")
    peer_connected=$(jq -r '.peer_connected // "unknown"' "$STATUS_FILE")
    syncthing_ready=$(jq -r '.syncthing_ready // "unknown"' "$STATUS_FILE")
    quic_ok=$(jq -r '.quic_ok // "unknown"' "$STATUS_FILE")

    json_init

    json_add "timestamp" "$(date -Iseconds)"
    json_add "node_role" "$(jq -r '.node_role' "$STATUS_FILE")"
    json_add "api_url" "$(jq -r '.api_url' "$STATUS_FILE")"
    json_add "peer_target" "$(jq -r '.peer_target' "$STATUS_FILE")"

    json_add_object_start "health"
    json_add "api_ok" "$api_ok"
    json_add "peer_connected" "$peer_connected"
    json_add "syncthing_ready" "$syncthing_ready"
    json_add "quic_ok" "$quic_ok"
    json_add "mesh_ok" "$mesh_ok"
    json_add_object_end

    json_close "$OUT_FILE"

    log "INFO" "Phoenix status written to $OUT_FILE" "$GREEN"
}

main "$@"
