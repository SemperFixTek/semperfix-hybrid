#!/usr/bin/env bash

# =====================================================================
# Phoenix Automation Suite — Heartbeat
# Version: Phoenix v2.1
# Component: phoenix-heartbeat
# Role: Controller / Responder / Observer (role-aware)
# Refactor: 2026-11-07 — v2.0 → v2.1.1 role model upgrade
# Maintainer: SemperFix Automation (Bruce)
# Audit 2026-11-07
# =====================================================================

set -euo pipefail

umask 002
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

dos2unix "$0" >/dev/null 2>&1 || true

# shellcheck disable=SC1091
source /opt/semperfix/scripts/phoenix-core.sh
# shellcheck disable=SC1091
source /opt/semperfix/scripts/phoenix-json.sh

phoenix_init

HEARTBEAT_FILE="${STATE_DIR}/phoenix-heartbeat.json"
LOGFILE="${LOG_DIR}/phoenix-heartbeat.log"
LOCKFILE="/run/lock/phoenix-heartbeat.lock"

# shellcheck disable=SC2034
PHOENIX_LOGFILE="$LOGFILE"

log() {
    phoenix_log_file "INFO" "$*"
}

# ------------------------------------------------------------
# Locking
# ------------------------------------------------------------

exec 200>"$LOCKFILE"

flock -n 200 || {
    log "Heartbeat already running"
    exit 0
}

# ------------------------------------------------------------
# Cached Syncthing Status
# ------------------------------------------------------------

fetch_status() {
    curl -s --connect-timeout 2 --max-time 5 -H "X-API-Key: ${API_KEY}" \
        "${API_URL}/system/status" || echo "{}"
}

STATUS_JSON_CACHE="$(fetch_status)"

# ------------------------------------------------------------
# Helpers
# ------------------------------------------------------------

read_state_value() {

    local file="$1"
    local key="$2"

    jq -r ".${key} // \"unknown\"" "$file" 2>/dev/null || echo "unknown"
}

# ------------------------------------------------------------
# Health Checks
# ------------------------------------------------------------

check_api() {

    jq -e '.myID != null' <<< "$STATUS_JSON_CACHE" >/dev/null 2>&1
}

check_syncthing_ready() {

    jq -r '.myID != null' <<< "$STATUS_JSON_CACHE" 2>/dev/null || echo false
}

check_quic_listener() {

    jq -e '(.connectionServiceStatus["quic://0.0.0.0:${PEER_PORT}"].error) == null
        ' <<< "$STATUS_JSON_CACHE" >/dev/null 2>&1
}

check_peer_connected() {

    local handshake

    handshake="${STATE_DIR}/mesh-handshake.json"

    if [[ ! -f "$handshake" ]]; then
        echo "unknown"
        return
    fi

    jq -r '.handshake_status == "pass"' "$handshake" 2>/dev/null || echo false
}

check_mesh_ok() {

    local handshake
    local verify
    local activate

    handshake=$(
        read_state_value "${STATE_DIR}/mesh-handshake.json" "handshake_status"
    )

    verify=$(
        read_state_value "${STATE_DIR}/mesh-verify.json" "verify_status"
    )

    activate=$(
        read_state_value "${STATE_DIR}/mesh-activate.json" "activate_status"
    )

    if [[ "$handshake" == "pass" &&
          "$verify"    == "pass" &&
          "$activate"  == "pass"
    ]]; then
        echo "true"
    else
        echo "false"
    fi
}

# ------------------------------------------------------------
# Main
# ------------------------------------------------------------

main() {

    log "Phoenix Heartbeat for role: ${NODE_ROLE}"

    local api_ok="false"
    local syncthing_ready="false"
    local peer_connected="not_applicable"
    local quic_ok="not_applicable"
    local mesh_ok="not_applicable"

    if check_api; then
        api_ok="true"
    fi

    syncthing_ready=$(check_syncthing_ready)

    case "$NODE_ROLE" in

        MASTERZERO-ACTIVE|MASTERZERO-DEGRADED|MASTERZERO-RECOVER|SECONDARY-ACTIVE)

            peer_connected=$(check_peer_connected)

            if check_quic_listener; then
                quic_ok="true"
            else
                quic_ok="false"
            fi

            mesh_ok=$(check_mesh_ok)
            ;;

        SECONDARY-PASSIVE)

            log "Passive heartbeat"

            if systemctl is-active --quiet semperfix-quic-responder.service
            then
                quic_ok="true"
            else
                quic_ok="false"
            fi

            peer_connected=$(check_peer_connected)

            mesh_ok="not_applicable"
            ;;

        OFFSITE)

            log "OFFSITE heartbeat"

            peer_connected="not_applicable"
            quic_ok="not_applicable"
            mesh_ok="not_applicable"
            ;;

        *)

            log "Unknown role: ${NODE_ROLE}"
            ;;

    esac

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