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

LOGFILE="/opt/semperfix/logs/mesh-activate.log"
JSON_OUT="/opt/semperfix/logs/mesh-activate.json"

# ---------- Syncthing Readiness ----------
check_readiness() {
    local api_url="$1"
    local api_key="$2"

    log "INFO" "Checking Syncthing readiness" "$BLUE"

    local status
    status=$(curl -s -H "X-API-Key: ${api_key}" "${api_url}/system/status")

    echo "$status" >> "$LOGFILE"

    if echo "$status" | jq -e '.majorSyncing == false' >/dev/null 2>&1; then
        log "PASS" "Syncthing ready for activation" "$GREEN"
        json_set "$JSON_OUT" "syncthing_ready" "true"
    else
        log "WARN" "Syncthing still syncing" "$YELLOW"
        json_set "$JSON_OUT" "syncthing_ready" "false"
    fi
}

# ---------- QUIC Activation ----------
activate_quic() {
    local target_ip="$1"
    local target_port="$2"

    log "INFO" "Attempting QUIC activation to ${target_ip}:${target_port}" "$BLUE"

    if echo "activate" | nc -u -w1 "${target_ip}" "${target_port}" &>/dev/null; then
        log "PASS" "QUIC activation packet sent" "$GREEN"
        json_set "$JSON_OUT" "quic_activation" "sent"
        return 0
    else
        log "FAIL" "QUIC activation failed" "$RED"
        json_set "$JSON_OUT" "quic_activation" "failed"
        return 0
    fi
}

# ---------- Post-Activation Peer Check ----------
verify_peer_after_activation() {
    local api_url="$1"
    local api_key="$2"

    log "INFO" "Rechecking peer connectivity after activation" "$BLUE"

    local matrix
    matrix=$(curl -s -H "X-API-Key: ${api_key}" "${api_url}/system/connections")

    echo "$matrix" >> "$LOGFILE"

    if [[ "$matrix" == *"connected\": true"* ]]; then
        log "PASS" "Peer connected after activation" "$GREEN"
        json_set "$JSON_OUT" "peer_connected_after_activation" "true"
        return 0
    else
        log "FAIL" "Peer still disconnected after activation" "$RED"
        json_set "$JSON_OUT" "peer_connected_after_activation" "false"
        return 0
    fi
}

# ---------- Main ----------
main() {
    mkdir -p /opt/semperfix/logs
    : > "$LOGFILE"

    json_init "$JSON_OUT"

    log "INFO" "Starting Phoenix Mesh Activation for role: ${NODE_ROLE}" "$YELLOW"

    json_set "$JSON_OUT" "timestamp" "$(date -Iseconds)"
    json_set "$JSON_OUT" "node_role" "$NODE_ROLE"
    json_set "$JSON_OUT" "api_url" "$API_URL"
    json_set "$JSON_OUT" "peer_target" "${PEER_IP}:${PEER_PORT}"

    case "$NODE_ROLE" in

        MASTERZERO)
            log "INFO" "MASTERZERO performing full mesh activation" "$BLUE"

            check_readiness "$API_URL" "$API_KEY"
            activate_quic "$PEER_IP" "$PEER_PORT"
            verify_peer_after_activation "$API_URL" "$API_KEY"
            ;;

        SECONDARY)
            log "INFO" "SECONDARY performing responder-side activation diagnostics" "$BLUE"

            # SECONDARY does NOT send activation packets
            check_readiness "$API_URL" "$API_KEY"

            json_set "$JSON_OUT" "quic_activation" "handled_by_responder"
            json_set "$JSON_OUT" "peer_connected_after_activation" "handled_by_responder"
            ;;

        OFFSITE)
            log "INFO" "OFFSITE performing observer-only activation" "$BLUE"

            # OFFSITE does NOT participate in QUIC activation
            check_readiness "$API_URL" "$API_KEY"

            json_set "$JSON_OUT" "quic_activation" "not_applicable"
            json_set "$JSON_OUT" "peer_connected_after_activation" "not_applicable"
            ;;

        *)
            log "FAIL" "Unknown node role: ${NODE_ROLE}" "$RED"
            json_set "$JSON_OUT" "error" "invalid_node_role"
            ;;
    esac

    log "INFO" "Mesh activation complete" "$GREEN"
    json_finalize "$JSON_OUT"
}


main "$@"
