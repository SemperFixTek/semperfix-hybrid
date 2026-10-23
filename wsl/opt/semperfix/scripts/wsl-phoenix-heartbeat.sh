#!/usr/bin/env bash
# =====================================================================
# Phoenix Automation Suite — Heartbeat
# Version: Phoenix v2.1
# Component: phoenix-heartbeat
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

HEARTBEAT_FILE="${STATE_DIR}/phoenix-heartbeat.json"
LOGFILE="${LOG_DIR}/phoenix-heartbeat.log"

PHOENIX_LOGFILE="$LOGFILE"
log() { phoenix_log_file "INFO" "$*"; }

# =====================================================================
# Health Checks
# =====================================================================

check_api() {
    curl -s -o /dev/null -w "%{http_code}" \
        -H "X-API-Key: $API_KEY" \
        "$API_URL/system/status" 2>/dev/null
}

check_syncthing_ready() {
    curl -s -H "X-API-Key: $API_KEY" "$API_URL/system/status" \
        | jq -r '.myID != null' 2>/dev/null
}

check_peer_connected() {
    jq -r '
        if (.peer_dump.connections | type == "object")
        then (.peer_dump.connections | to_entries | map(.value.connected) | any)
        else false
        end
    ' "${STATE_DIR}/mesh-handshake.json" 2>/dev/null
}

check_quic() {
    nc -zvu "$PEER_IP" "$PEER_PORT" 2>/dev/null
}

check_mesh_ok() {
    jq -r '
        (.handshake_status == "pass")
        and (.verify_status == "pass")
        and (.activate_status == "pass")
    ' "${STATE_DIR}/phoenix-supervisor.json" 2>/dev/null
}

# =====================================================================
# Main
# =====================================================================

main() {
    log "Phoenix v2.1 Heartbeat for role: ${NODE_ROLE}"

    local api_ok="false"
    local syncthing_ready="false"
    local peer_connected="not_applicable"
    local quic_ok="not_applicable"
    local mesh_ok="not_applicable"

    # Always run API + Syncthing checks
    api_ok=$(check_api || echo "false")
    [[ "$api_ok" == "200" ]] && api_ok="true" || api_ok="false"

    syncthing_ready=$(check_syncthing_ready || echo "false")

    case "$NODE_ROLE" in

        MASTERZERO-ACTIVE|MASTERZERO-DEGRADED|MASTERZERO-RECOVER|SECONDARY-ACTIVE)
            # Full controller heartbeat
            peer_connected=$(check_peer_connected || echo "false")

            if check_quic >/dev/null 2>&1; then
                quic_ok="true"
            else
                quic_ok="false"
                log "QUIC probe failed for $PEER_IP:$PEER_PORT"
            fi

            mesh_ok=$(check_mesh_ok || echo "false")
            ;;

        SECONDARY-PASSIVE)
            log "Passive heartbeat: limited controller checks"

            # QUIC responder health
            if systemctl is-active --quiet semperfix-quic-responder.service; then
                quic_ok="true"
            else
                quic_ok="false"
            fi

            # Passive mesh handshake
            peer_connected=$(check_peer_connected || echo "false")
            mesh_ok="not_applicable"
            ;;

        OFFSITE)
            log "OFFSITE heartbeat: minimal checks only"
            ;;

        *)
            log "Unknown node role: ${NODE_ROLE}"
            ;;
    esac

    # =====================================================================
    # Unified JSON Writer
    # =====================================================================

    json_init "$HEARTBEAT_FILE"

    json_set "$HEARTBEAT_FILE" "timestamp" "$(date -Iseconds)"
    json_set "$HEARTBEAT_FILE" "node_role" "$NODE_ROLE"
    json_set "$HEARTBEAT_FILE" "api_ok" "$api_ok"
    json_set "$HEARTBEAT_FILE" "syncthing_ready" "$syncthing_ready"
    json_set "$HEARTBEAT_FILE" "peer_connected" "$peer_connected"
    json_set "$HEARTBEAT_FILE" "quic_ok" "$quic_ok"
    json_set "$HEARTBEAT_FILE" "mesh_ok" "$mesh_ok"

    json_finalize "$HEARTBEAT_FILE"
    /opt/semperfix/scripts/json-perms.sh "$HEARTBEAT_FILE"

    log "Heartbeat written to $HEARTBEAT_FILE"
}

main "$@"
