#!/usr/bin/env bash
# =====================================================================
# Phoenix Automation Suite — Mesh Status
# Version: Phoenix v2.1
# Component: wsl-mesh-status
# Role: Controller / Responder / Observer (role-aware)
# Refactor: 2026-10-21 — v2.0 → v2.1 role model upgrade
# Maintainer: SemperFix Automation (Bruce)
# =====================================================================

set -euo pipefail

umask 002
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

dos2unix "$0" 2>/dev/null || true

source /opt/semperfix/scripts/phoenix-core.sh
source /opt/semperfix/scripts/phoenix-json.sh
phoenix_init

STATUS_LOG="${LOG_DIR}/mesh-status.log"
STATUS_JSON="${STATE_DIR}/mesh-status.json"

PHOENIX_LOGFILE="$STATUS_LOG"
log() { phoenix_log_file "INFO" "$*"; }

check_api() {
    local pong
    pong=$(curl -s -H "X-API-Key: ${API_KEY}" "${API_URL}/system/ping" || echo "error")

    log "API ping result: ${pong}"

    if [[ "$pong" == *"pong"* ]]; then
        json_set "$STATUS_JSON" "api_ok" "true"
    else
        json_set "$STATUS_JSON" "api_ok" "false"
    fi
}

check_connections() {
    local matrix
    matrix=$(curl -s -H "X-API-Key: ${API_KEY}" "${API_URL}/system/connections")

    printf "%s\n" "$matrix" >> "$STATUS_LOG"

    local connected
    connected=$(jq -r '.connections | length > 0' <<< "$matrix" 2>/dev/null || echo "false")

    if [[ "$connected" == "true" ]]; then
        json_set "$STATUS_JSON" "peer_connected" "true"
    else
        json_set "$STATUS_JSON" "peer_connected" "false"
    fi
}

main() {
    log "Phoenix Mesh Status (v2.1) — role: ${NODE_ROLE}"

    json_init "$STATUS_JSON"
    json_set "$STATUS_JSON" "timestamp" "$(date -Iseconds)"
    json_set "$STATUS_JSON" "node_role" "$NODE_ROLE"

    case "$NODE_ROLE" in

        MASTERZERO-ACTIVE|MASTERZERO-DEGRADED|MASTERZERO-RECOVER|SECONDARY-ACTIVE)
            log "${NODE_ROLE}: full mesh status check"

            check_api
            check_connections

            json_set "$STATUS_JSON" "handshake_status" "$(jq -r '.handshake_status' "${STATE_DIR}/phoenix-supervisor.json" 2>/dev/null || echo "unknown")"
            json_set "$STATUS_JSON" "verify_status"    "$(jq -r '.verify_status'    "${STATE_DIR}/phoenix-supervisor.json" 2>/dev/null || echo "unknown")"
            json_set "$STATUS_JSON" "activate_status"  "$(jq -r '.activate_status'  "${STATE_DIR}/phoenix-supervisor.json" 2>/dev/null || echo "unknown")"
            ;;

        SECONDARY-PASSIVE)
            log "SECONDARY-PASSIVE: passive mesh status"

            check_api
            check_connections

            json_set "$STATUS_JSON" "handshake_status" "$(jq -r '.handshake_status' "${STATE_DIR}/mesh-handshake.json" 2>/dev/null || echo "unknown")"
            json_set "$STATUS_JSON" "verify_status" "not_applicable"
            json_set "$STATUS_JSON" "activate_status" "not_applicable"
            ;;

        OFFSITE)
            log "OFFSITE: limited mesh status"

            check_api
            json_set "$STATUS_JSON" "peer_connected" "not_applicable"
            json_set "$STATUS_JSON" "handshake_status" "not_applicable"
            json_set "$STATUS_JSON" "verify_status" "not_applicable"
            json_set "$STATUS_JSON" "activate_status" "not_applicable"
            ;;

        *)
            log "Invalid node role: ${NODE_ROLE}"
            json_set "$STATUS_JSON" "error" "invalid_node_role"
            ;;
    esac

    json_finalize "$STATUS_JSON"
    /opt/semperfix/scripts/json-perms.sh "$STATUS_JSON"

    log "Mesh status written to $STATUS_JSON"
}

main "$@"
