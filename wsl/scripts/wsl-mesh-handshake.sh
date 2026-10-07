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


source /opt/semperfix/scripts/phoenix-core.sh
source /opt/semperfix/scripts/phoenix-json.sh
phoenix_load_config

STATE_DIR="/var/lib/semperfix/state"
LOG_DIR="/opt/semperfix/logs"

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

LOGFILE="${LOG_DIR}/mesh-handshake.log"
JSON_OUT="${LOG_DIR}/mesh-handshake.json"

# ---------- QUIC Check ----------
check_quic() {
    local target_ip="$1"
    local target_port="$2"

    log "INFO" "Checking QUIC reachability to ${target_ip}:${target_port}" "$BLUE"

    if nc -zvu "${target_ip}" "${target_port}" &>/dev/null; then
        log "PASS" "QUIC reachable" "$GREEN"
        json_set "$JSON_OUT" "quic_status" "reachable"
        return 0
    else
        log "FAIL" "QUIC unreachable" "$RED"
        json_set "$JSON_OUT" "quic_status" "unreachable"
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
        json_set "$JSON_OUT" "syncthing_api" "reachable"
        return 0
    else
        log "FAIL" "Syncthing API unreachable" "$RED"
        json_set "$JSON_OUT" "syncthing_api" "unreachable"
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
    json_set_raw "$JSON_OUT" "peer_dump" "$peers"
}

# ---------- Main ----------
main() {
    mkdir -p "$LOG_DIR"
    : > "$LOGFILE"

    json_init "$JSON_OUT"

    log "INFO" "Starting Phoenix Mesh Handshake for role: ${NODE_ROLE}" "$YELLOW"

    json_set "$JSON_OUT" "timestamp" "$(date -Iseconds)"
    json_set "$JSON_OUT" "node_role" "$NODE_ROLE"
    json_set "$JSON_OUT" "api_url" "$API_URL"
    json_set "$JSON_OUT" "peer_target" "${PEER_IP}:${PEER_PORT}"

    case "$NODE_ROLE" in

        MASTERZERO)
            log "INFO" "MASTERZERO initiating full mesh handshake" "$BLUE"

            check_syncthing_api "$API_URL" "$API_KEY"
            check_quic "$PEER_IP" "$PEER_PORT"
            dump_peers "$API_URL" "$API_KEY"

            ;;

        SECONDARY)
            log "INFO" "SECONDARY performing responder-side diagnostics" "$BLUE"

            # SECONDARY does NOT probe QUIC — responder handles that
            check_syncthing_api "$API_URL" "$API_KEY"
            dump_peers "$API_URL" "$API_KEY"

            json_set "$JSON_OUT" "quic_status" "handled_by_responder"

            ;;

        OFFSITE)
            log "INFO" "OFFSITE performing observer-only handshake" "$BLUE"

            # OFFSITE does NOT probe QUIC and does NOT dump peers
            check_syncthing_api "$API_URL" "$API_KEY"

            json_set "$JSON_OUT" "quic_status" "not_applicable"
            json_set "$JSON_OUT" "peer_dump" "not_applicable"

            ;;

        *)
            log "FAIL" "Unknown node role: ${NODE_ROLE}" "$RED"
            json_set "$JSON_OUT" "error" "invalid_node_role"
            ;;
    esac

    log "INFO" "Handshake diagnostics complete" "$GREEN"
    json_finalize "$JSON_OUT"
}


main "$@"
