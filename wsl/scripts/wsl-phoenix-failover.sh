#!/usr/bin/env bash
set -euo pipefail

HEARTBEAT_FILE="/opt/semperfix/state/phoenix-heartbeat.json"
FAILOVER_FILE="/opt/semperfix/state/phoenix-failover.json"
LOGFILE="/opt/semperfix/logs/phoenix-failover.log"

# ---------- Color Codes ----------
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
NC="\033[0m"

log() {
    local level="$1"
    local msg="$2"
    local color="$3"

    echo -e "${color}[${level}]${NC} ${msg}"
    echo "[${level}] ${msg}" >> "$LOGFILE"
}

json_init() {
    echo "{" > "$FAILOVER_FILE"
}

json_add() {
    local key="$1"
    local value="$2"

    value=$(printf '%s' "$value" | jq -Rsa .)
    value="${value:1:${#value}-2}"

    echo "  \"${key}\": \"${value}\"," >> "$FAILOVER_FILE"
}

json_close() {
    sed -i '$ s/,$//' "$FAILOVER_FILE"
    echo "}" >> "$FAILOVER_FILE"
}

main() {
    mkdir -p /opt/semperfix/state
    mkdir -p /opt/semperfix/logs
    : > "$LOGFILE"

    log "INFO" "Phoenix Failover (v2, heartbeat-aware)" "$BLUE"

    if [[ ! -f "$HEARTBEAT_FILE" ]]; then
        log "FAIL" "Heartbeat file missing — cannot evaluate failover" "$RED"
        exit 0
    fi

    local mesh_ok
    mesh_ok=$(jq -r '.mesh_ok' "$HEARTBEAT_FILE")

    json_init
    json_add "timestamp" "$(date -Iseconds)"
    json_add "mesh_ok" "$mesh_ok"

    if [[ "$mesh_ok" == "true" ]]; then
        log "PASS" "Mesh healthy — no failover required" "$GREEN"
        json_add "failover_required" "false"
        json_close
        exit 0
    fi

    log "WARN" "Mesh unhealthy or supervisor failed — failover required" "$YELLOW"
    json_add "failover_required" "true"

    # QUIC escalation packet
    if echo "failover" | nc -u -w1 "${PEER_IP}" "${PEER_PORT}" &>/dev/null; then
        log "PASS" "Failover packet sent" "$GREEN"
        json_add "failover_packet" "sent"
    else
        log "FAIL" "Failover packet failed" "$RED"
        json_add "failover_packet" "failed"
    fi

    json_close
}

main "$@"
