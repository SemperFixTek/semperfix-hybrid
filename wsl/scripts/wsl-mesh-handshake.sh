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

# ---------- Logging ----------
log() {
    local level="$1"
    local msg="$2"
    local color="$3"

    echo -e "${color}[${level}]${NC} ${msg}"
    echo "[${level}] ${msg}" >> "$LOGFILE"
}

LOGFILE="/opt/semperfix/logs/mesh-handshake.log"
JSON_OUT="/opt/semperfix/logs/mesh-handshake.json"

# ... colors + log() unchanged ...

check_quic() {
    local target_ip="$1"
    local target_port="$2"

    log "INFO" "Checking QUIC reachability to ${target_ip}:${target_port}" "$BLUE"

    if nc -zvu "${target_ip}" "${target_port}" &>/dev/null; then
        log "PASS" "QUIC reachable" "$GREEN"
        json_add "$JSON_OUT" "quic_status" "reachable"
        return 0
    else
        log "FAIL" "QUIC unreachable" "$RED"
        json_add "$JSON_OUT" "quic_status" "unreachable"
        return 1
    fi
}

check_syncthing_api() {
    local api_url="$1"
    local api_key="$2"

    log "INFO" "Checking Syncthing API at ${api_url}" "$BLUE"

    local status
    status=$(curl -s -H "X-API-Key: ${api_key}" "${api_url}/system/ping" || echo "error")

    if [[ "$status" == *"pong"* ]]; then
        log "PASS" "Syncthing API reachable" "$GREEN"
        json_add "$JSON_OUT" "syncthing_api" "reachable"
        return 0
    else
        log "FAIL" "Syncthing API unreachable" "$RED"
        json_add "$JSON_OUT" "syncthing_api" "unreachable"
        return 1
    fi
}

dump_peers() {
    local api_url="$1"
    local api_key="$2"

    log "INFO" "Dumping peer list" "$BLUE"

    local peers
    peers=$(curl -s -H "X-API-Key: ${api_key}" "${api_url}/system/connections")

    echo "$peers" >> "$LOGFILE"
    json_add_raw "$JSON_OUT" "peer_dump" "$peers"
}

main() {
    mkdir -p /opt/semperfix/logs
    : > "$LOGFILE"

    json_init "$JSON_OUT"

    log "INFO" "Starting Phoenix Mesh Handshake" "$YELLOW"
    json_add "$JSON_OUT" "timestamp" "$(date -Iseconds)"
    json_add "$JSON_OUT" "node_role" "$NODE_ROLE"
    json_add "$JSON_OUT" "api_url" "$API_URL"
    json_add "$JSON_OUT" "peer_target" "${PEER_IP}:${PEER_PORT}"

    check_syncthing_api "$API_URL" "$API_KEY"
    check_quic "$PEER_IP" "$PEER_PORT"
    dump_peers "$API_URL" "$API_KEY"

    log "INFO" "Handshake diagnostics complete" "$GREEN"
    json_close "$JSON_OUT"
}

main "$@"
