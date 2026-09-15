#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Phoenix Mesh Handshake — SemperFix Edition
# Drop‑in replacement with:
# - Structured logging
# - Color-coded output
# - JSON diagnostic export
# ============================================================

# ---------- Color Codes ----------
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
NC="\033[0m"   # No Color

# ---------- Logging ----------
LOGFILE="/opt/semperfix/logs/mesh-handshake.log"
JSON_OUT="/opt/semperfix/logs/mesh-handshake.json"

log() {
    local level="$1"
    local msg="$2"
    local color="$3"

    echo -e "${color}[${level}]${NC} ${msg}"
    echo "[${level}] ${msg}" >> "$LOGFILE"
}

# ---------- JSON Builder ----------
json_init() {
    echo "{" > "$JSON_OUT"
}

json_add() {
    local key="$1"
    local value="$2"
    echo "  \"${key}\": \"${value}\"," >> "$JSON_OUT"
}

json_close() {
    sed -i '$ s/,$//' "$JSON_OUT"
    echo "}" >> "$JSON_OUT"
}

# ---------- QUIC Diagnostic ----------
check_quic() {
    local target_ip="$1"
    local target_port="$2"

    log "INFO" "Checking QUIC reachability to ${target_ip}:${target_port}" "$BLUE"

    if nc -zvu "${target_ip}" "${target_port}" &>/dev/null; then
        log "PASS" "QUIC reachable" "$GREEN"
        json_add "quic_status" "reachable"
        return 0
    else
        log "FAIL" "QUIC unreachable" "$RED"
        json_add "quic_status" "unreachable"
        return 1
    fi
}

# ---------- Syncthing API Check ----------
check_syncthing_api() {
    local api_url="$1"
    local api_key="$2"

    log "INFO" "Checking Syncthing API at ${api_url}" "$BLUE"

    local status
    status=$(curl -s -H "X-API-Key: ${api_key}" "${api_url}/system/ping" || echo "error")

    if [[ "$status" == *"pong"* ]]; then
        log "PASS" "Syncthing API reachable" "$GREEN"
        json_add "syncthing_api" "reachable"
        return 0
    else
        log "FAIL" "Syncthing API unreachable" "$RED"
        json_add "syncthing_api" "unreachable"
        return 1
    fi
}

# ---------- Peer Dump ----------
dump_peers() {
    local api_url="$1"
    local api_key="$2"

    log "INFO" "Dumping peer list" "$BLUE"

    local peers
    peers=$(curl -s -H "X-API-Key: ${api_key}" "${api_url}/system/connections")

    echo "$peers" >> "$LOGFILE"
    json_add "peer_dump" "$(echo "$peers" | tr -d '"')"
}

# ---------- Main ----------
main() {
    mkdir -p /opt/semperfix/logs
    : > "$LOGFILE"

    json_init

    log "INFO" "Starting Phoenix Mesh Handshake" "$YELLOW"
    json_add "timestamp" "$(date -Iseconds)"

    # These values should already be correct for MASTERZERO
    local API_URL="http://127.0.0.1:8384/rest"
    local API_KEY="${SYNCTHING_API_KEY:-UNSET}"
    local PEER_IP="10.10.10.2"
    local PEER_PORT="22000"

    json_add "node_role" "MASTERZERO"
    json_add "api_url" "$API_URL"
    json_add "peer_target" "${PEER_IP}:${PEER_PORT}"

    # Run diagnostics
    check_syncthing_api "$API_URL" "$API_KEY"
    check_quic "$PEER_IP" "$PEER_PORT"
    dump_peers "$API_URL" "$API_KEY"

    log "INFO" "Handshake diagnostics complete" "$GREEN"
    json_close
}

main "$@"
