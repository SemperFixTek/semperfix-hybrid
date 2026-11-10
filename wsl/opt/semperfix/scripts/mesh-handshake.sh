#!/usr/bin/env bash

# =====================================================================
# Phoenix Automation Suite — Mesh Handshake
# Version: Phoenix v2.1
# Component: wsl-mesh-handshake
# Role: Controller / Responder / Observer (role‑aware)
# Refactor: 2026-10-21 — v2.0 → v2.1 role model upgrade
# Maintainer: SemperFix Automation (Bruce)     
# Audit 2026-11-05
# =====================================================================

set -euo pipefail

umask 002
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

# Safety: prevent CRLF issues
dos2unix "$0" 2>/dev/null || true

# Load Phoenix core + JSON helpers

# shellcheck disable=SC1091
source /opt/semperfix/scripts/phoenix-core.sh
# shellcheck disable=SC1091
source /opt/semperfix/scripts/phoenix-json.sh
phoenix_init

LOGFILE="${LOG_DIR}/mesh-handshake.log"
JSON_OUT="${STATE_DIR}/mesh-handshake.json"
LOCKFILE="/run/lock/mesh-handshake.lock"

# shellcheck disable=SC2034
PHOENIX_LOGFILE="$LOGFILE"

# ------------------------------------------------------------
# Locking
# ------------------------------------------------------------

exec 200>"$LOCKFILE"

if ! flock -n 200; then
    echo "[WARN] Another mesh-handshake is already running"
    exit 1
fi

log() { phoenix_log_file "INFO" "$*"; } 

check_transport() {
    log "Checking peer connectivity"
    log "Peer target: ${PEER_IP}:${PEER_PORT} (device ID: ${PEER_DEVICE_ID})"

    local connected

    connected=$(api_get "system/connections" | jq -r \
               ".connections.\"${PEER_DEVICE_ID}\".connected // false"
    )

    if [[ "$connected" == "true" ]]; then
        json_set "$JSON_OUT" "peer_status" "connected"
        log "connected"
        return 0
    fi

    json_set "$JSON_OUT" "peer_status" "disconnected"
    log "disconnected"
    return 1
}

api_get() {

    local endpoint="$1"

    curl -s --connect-timeout 2 --max-time 5 \
         -H "X-API-Key: ${API_KEY}" "${API_URL}/${endpoint}"
}

check_syncthing_api() {
    log "Checking Syncthing API at ${API_URL}"
    local status
    
    status=$(api_get "system/ping" || echo "error")

    if [[ "$status" == *"pong"* ]]; then
            log "Syncthing API reachable"
            json_set "$JSON_OUT" "syncthing_api" "reachable"
        return 0
    else
            log "Syncthing API unreachable"
            json_set "$JSON_OUT" "syncthing_api" "unreachable"
        return 1
    fi
}

dump_peers() {

    log "Dumping peer list"
    local peers

    peers=$(api_get "system/connections" || echo "{}")

    if jq -e . >/dev/null <<< "$peers"; then
        json_set_raw "$JSON_OUT" "peer_dump" "$peers"

    else
        log "Peer dump was not valid JSON"
        json_set_raw "$JSON_OUT" "peer_dump" "null"
    fi
}

main() {
    log "Starting Phoenix Mesh Handshake for role: ${NODE_ROLE}"

    json_init "$JSON_OUT"
    json_set "$JSON_OUT" "timestamp" "$(date -Iseconds)"
    json_set "$JSON_OUT" "node_role" "$NODE_ROLE"
    json_set "$JSON_OUT" "api_url" "$API_URL"
    json_set "$JSON_OUT" "peer_target" "${PEER_IP}:${PEER_PORT}"

    local handshake_status="fail"
    local syncthing_status="fail"
    local quic_status="fail"

    case "$NODE_ROLE" in

        MASTERZERO-ACTIVE|MASTERZERO-DEGRADED|MASTERZERO-RECOVER)
            log "${NODE_ROLE} initiating full mesh handshake"

            if check_syncthing_api; then
                syncthing_status="pass"
            else
                syncthing_status="fail"
            fi

            if check_transport; then
                quic_status="pass"
            else
                quic_status="fail"
            fi

            dump_peers

            if [[ "$syncthing_status" == "pass" &&
                "$quic_status" == "pass" ]]; then
                handshake_status="pass"
            else
                handshake_status="fail"
            fi

            ;;

        SECONDARY-ACTIVE)
            log "SECONDARY-ACTIVE performing controller-side handshake"
            if check_syncthing_api; then
                syncthing_status="pass"
            else
                syncthing_status="fail"
            fi

            if check_transport; then
                quic_status="pass"
            else
                quic_status="fail"
            fi

            dump_peers

            if [[ "$syncthing_status" == "pass" &&
                "$quic_status" == "pass" ]]; then
                handshake_status="pass"
            else
                handshake_status="fail"
            fi
            ;;

        SECONDARY-PASSIVE)
            log "SECONDARY-PASSIVE performing responder-side diagnostics"
            
            if check_syncthing_api; then
                syncthing_status="pass"
            else
                syncthing_status="fail"
            fi

            dump_peers

            if [[ "$syncthing_status" == "pass" ]]; then
                handshake_status="pass"
            else
                handshake_status="fail"
            fi
        
            json_set "$JSON_OUT" "quic_status" "handled_by_responder"
            
            ;;

        OFFSITE)
            log "OFFSITE performing observer-only handshake"
            
            if check_syncthing_api; then
                syncthing_status="pass"
            else
                syncthing_status="fail"
            fi
            
            dump_peers

            if [[ "$syncthing_status" == "pass" ]]; then
                handshake_status="pass"
            else
                handshake_status="fail"
            fi
            
            json_set "$JSON_OUT" "quic_status" "not_applicable"

            ;;

        *)
            log "Unknown node role: ${NODE_ROLE}"
            json_set "$JSON_OUT" "error" "invalid_node_role"
            handshake_status="fail"
            ;;
    esac

    json_set "$JSON_OUT" "handshake_status" "$handshake_status"

    log "Handshake diagnostics complete"
    json_finalize "$JSON_OUT"

    /opt/semperfix/scripts/json-perms.sh "$JSON_OUT"
}

main "$@"
