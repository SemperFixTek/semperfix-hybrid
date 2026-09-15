#!/usr/bin/env bash
set -euo pipefail

source /opt/semperfix/scripts/phoenix-core.sh
source /opt/semperfix/scripts/phoenix-json.sh
phoenix_load_config

HANDSHAKE_SCRIPT="/opt/semperfix/scripts/wsl-mesh-handshake.sh"
VERIFY_SCRIPT="/opt/semperfix/scripts/wsl-mesh-verify.sh"
ACTIVATE_SCRIPT="/opt/semperfix/scripts/wsl-mesh-activate.sh"

SUP_LOG="/opt/semperfix/logs/phoenix-supervisor.log"
SUP_JSON="/opt/semperfix/logs/phoenix-supervisor.json"

RED="\033[0;31m"; GREEN="\033[0;32m"; YELLOW="\033[1;33m"; BLUE="\033[0;34m"; NC="\033[0m"

log() {
    echo -e "${3}[${1}]${NC} ${2}"
    echo "[${1}] ${2}" >> "$SUP_LOG"
}

run_module() {
    local name="$1"
    local script="$2"

    log "INFO" "Running module: $name" "$BLUE"

    if bash "$script"; then
        log "PASS" "$name completed successfully" "$GREEN"
        json_add "$SUP_JSON" "${name}_status" "pass"
    else
        log "FAIL" "$name failed" "$RED"
        json_add "$SUP_JSON" "${name}_status" "fail"
    fi

    return 0
}

main() {
    mkdir -p /opt/semperfix/logs
    : > "$SUP_LOG"

    json_init "$SUP_JSON"
    log "INFO" "Starting Phoenix v2 Supervisor" "$YELLOW"

    json_add "$SUP_JSON" "timestamp" "$(date -Iseconds)"
    json_add "$SUP_JSON" "node_role" "$NODE_ROLE"
    json_add "$SUP_JSON" "api_url" "$API_URL"
    json_add "$SUP_JSON" "peer_target" "${PEER_IP}:${PEER_PORT}"

    run_module "handshake" "$HANDSHAKE_SCRIPT"
    run_module "verify" "$VERIFY_SCRIPT"
    run_module "activate" "$ACTIVATE_SCRIPT"

    log "INFO" "Phoenix v2 Supervisor complete" "$GREEN"
    json_close "$SUP_JSON"
}

main "$@"
