#!/usr/bin/env bash
set -euo pipefail

source /opt/semperfix/scripts/phoenix-core.sh
source /opt/semperfix/scripts/phoenix-json.sh
phoenix_load_config

LOGFILE="/opt/semperfix/logs/mesh-handshake.log"
JSON_OUT="/opt/semperfix/logs/mesh-handshake.json"

RED="\033[0;31m"
GREEN="\033[0;32m" 
YELLOW="\033[1;33m" 
BLUE="\033[0;34m" 
NC="\033[0m"

log() {
    echo -e "${3}[${1}]${NC} ${2}"
    echo "[${1}] ${2}" >> "$LOGFILE"
}

check_api() {
    log "INFO" "Checking Syncthing API at $API_URL" "$BLUE"
    if curl -s -H "X-API-Key: $API_KEY" "$API_URL/system/status" >/dev/null; then
        log "PASS" "Syncthing API reachable" "$GREEN"
        json_add "$JSON_OUT" "api_ok" "true"
    else
        log "FAIL" "Syncthing API unreachable" "$RED"
        json_add "$JSON_OUT" "api_ok" "false"
    fi
}

check_quic() {
    log "INFO" "Checking QUIC reachability to $PEER_IP:$PEER_PORT" "$BLUE"
    if echo "ping" | nc -u -w1 "$PEER_IP" "$PEER_PORT" &>/dev/null; then
        log "PASS" "QUIC reachable" "$GREEN"
        json_add "$JSON_OUT" "quic_ok" "true"
    else
        log "FAIL" "QUIC unreachable" "$RED"
        json_add "$JSON_OUT" "quic_ok" "false"
    fi
}

dump_peer_list() {
    log "INFO" "Dumping peer list" "$BLUE"
    curl -s -H "X-API-Key: $API_KEY" "$API_URL/system/connections" >> "$LOGFILE"
}

main() {
    mkdir -p /opt/semperfix/logs
    : > "$LOGFILE"

    json_init "$JSON_OUT"
    log "INFO" "Starting Phoenix Mesh Handshake" "$YELLOW"

    json_add "$JSON_OUT" "timestamp" "$(date -Iseconds)"
    json_add "$JSON_OUT" "node_role" "$NODE_ROLE"

    check_api
    check_quic
    dump_peer_list

    log "INFO" "Handshake diagnostics complete" "$GREEN"
    json_close "$JSON_OUT"
}

main "$@"
