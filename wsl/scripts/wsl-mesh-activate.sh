#!/usr/bin/env bash
# /opt/semperfix/scripts/wsl-mesh-activate.sh
# Phoenix v2 — Mesh Activation (MASTERZERO-driven)

set -euo pipefail

umask 002
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

STATE_DIR="/var/lib/semperfix/state"
LOG_DIR="/opt/semperfix/logs"
mkdir -p "$STATE_DIR" "$LOG_DIR"

# Normalize line endings once (safe no-op if already LF)
dos2unix /opt/semperfix/scripts/wsl-mesh-activate.sh >/dev/null 2>&1 || true

# Core + JSON helpers
source /opt/semperfix/scripts/phoenix-core.sh
source /opt/semperfix/scripts/phoenix-json.sh

phoenix_init

LOGFILE="${LOG_DIR}/mesh-activate.log"
JSON_OUT="${STATE_DIR}/mesh-activate.json"
PHOENIX_LOGFILE="$LOGFILE"

log() {
    phoenix_log_file INFO "$*"
}

error() {
    phoenix_log_file FAIL "$*"
}

json_init_safe() {
    local file="$1"
    echo '{}' >"$file"
}

json_set_safe() {
    local file="$1" key="$2" value="$3"
    local tmp
    tmp="$(mktemp)"
    jq --arg k "$key" --arg v "$value" '.[$k] = $v' "$file" >"$tmp"
    mv "$tmp" "$file"
}

check_syncthing_api() {
    log "Checking Syncthing API reachability"
    local status
    status="$(curl -s -H "X-API-Key: $API_KEY" "$API_URL/system/status" || true)"

    if [[ -z "$status" ]]; then
        error "Syncthing API unreachable at $API_URL/system/status"
        json_set_safe "$JSON_OUT" syncthing_ready "false"
        json_set_safe "$JSON_OUT" syncthing_api_ok "false"
        return 1
    fi

    json_set_safe "$JSON_OUT" syncthing_ready "true"
    json_set_safe "$JSON_OUT" syncthing_api_ok "true"
    log "Syncthing API reachable and responding"
    return 0
}

check_quic_listener() {
    log "Checking QUIC listener via Syncthing status"
    local status
    status="$(curl -s -H "X-API-Key: $API_KEY" "$API_URL/system/status" || true)"

    if ! printf '%s\n' "$status" | jq -e '.connectionServiceStatus["quic://0.0.0.0:22000"].error == null' >/dev/null 2>&1; then
        error "QUIC listener not healthy according to Syncthing status"
        json_set_safe "$JSON_OUT" quic_ok "false"
        return 1
    fi

    json_set_safe "$JSON_OUT" quic_ok "true"
    log "QUIC listener reported healthy"
    return 0
}

check_readiness() {
    log "Checking Syncthing + QUIC readiness (Phoenix v2)"

    if ! check_syncthing_api; then
        return 1
    fi

    if ! check_quic_listener; then
        return 1
    fi

    # Phoenix v2: we do NOT gate mesh activation on folder sync state.
    # Syncthing may be syncing or idle; mesh activation is independent.
    json_set_safe "$JSON_OUT" syncthing_ready "true"
    log "Phoenix v2 readiness check passed (API + QUIC OK)"
    return 0
}

activate_mesh_masterzero() {
    log "MASTERZERO performing full mesh activation"

    json_set_safe "$JSON_OUT" activation_role "MASTERZERO"
    json_set_safe "$JSON_OUT" peer_target "${PEER_IP}:${PEER_PORT}"

    if ! check_readiness; then
        error "Mesh activation aborted: readiness check failed"
        json_set_safe "$JSON_OUT" activation_success "false"
        return 1
    fi

    # QUIC activation probe (MASTERZERO → peer)
    log "Sending QUIC activation probe to ${PEER_IP}:${PHOENIX_QUIC_PORT}"
    if ! echo "phoenix-activate" | socat -u - UDP-SENDTO:"${PEER_IP}:${PHOENIX_QUIC_PORT}" >/dev/null 2>&1; then
        error "QUIC activation probe failed to ${PEER_IP}:${PHOENIX_QUIC_PORT}"
        json_set_safe "$JSON_OUT" quic_activation_sent "false"
        json_set_safe "$JSON_OUT" activation_success "false"
        return 1
    fi

    json_set_safe "$JSON_OUT" quic_activation_sent "true"
    json_set_safe "$JSON_OUT" activation_success "true"
    log "Mesh activation completed successfully for MASTERZERO"
    return 0
}

activate_mesh_secondary() {
    log "SECONDARY acknowledging mesh activation (no QUIC responder)"
    json_set_safe "$JSON_OUT" activation_role "SECONDARY"
    json_set_safe "$JSON_OUT" activation_success "true"
    return 0
}

activate_mesh_offsite() {
    log "OFFSITE node: mesh activation not applicable"
    json_set_safe "$JSON_OUT" activation_role "OFFSITE"
    json_set_safe "$JSON_OUT" activation_success "false"
    return 0
}

main() {
    log "Starting Phoenix Mesh Activation for role: $NODE_ROLE"

    json_init_safe "$JSON_OUT"
    json_set_safe "$JSON_OUT" timestamp "$(date -Iseconds)"
    json_set_safe "$JSON_OUT" node_role "$NODE_ROLE"
    json_set_safe "$JSON_OUT" api_url "$API_URL"
    json_set_safe "$JSON_OUT" peer_target "${PEER_IP}:${PEER_PORT}"

    case "$NODE_ROLE" in
        MASTERZERO)
            activate_mesh_masterzero
            ;;
        SECONDARY)
            activate_mesh_secondary
            ;;
        OFFSITE)
            activate_mesh_offsite
            ;;
        *)
            error "Unknown NODE_ROLE: $NODE_ROLE"
            json_set_safe "$JSON_OUT" activation_success "false"
            return 1
            ;;
    esac
}

main
