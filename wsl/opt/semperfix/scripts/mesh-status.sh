#!/usr/bin/env bash

# =====================================================================
# Phoenix Automation Suite — Mesh Status
# Version: Phoenix v2.1
# Component: wsl-mesh-status
# Role: Aggregator / Observer (role-aware)
# Refactor: 2026-11-07 — v2.0 → v2.1 role model upgrade
# Maintainer: SemperFix Automation (Bruce)
# Audit 2026-11-05
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

STATUS_LOG="${LOG_DIR}/mesh-status.log"
STATUS_JSON="${STATE_DIR}/mesh-status.json"

LOCKFILE=/run/lock/mesh-status.lock

# shellcheck disable=SC2034
PHOENIX_LOGFILE="$STATUS_LOG"

log() {
    phoenix_log_file INFO "$*"
}

#
# ------------------------------------------------------------
# Locking
# ------------------------------------------------------------
#

exec 200>"$LOCKFILE"

flock -n 200 || {
    log "[WARN] Another mesh-status already running"
    exit 0
}

#
# ------------------------------------------------------------
# API helper
# ------------------------------------------------------------
#

api_get() {

    local endpoint="$1"

    curl -s --connect-timeout 2 --max-time 5 \
        -H "X-API-Key: ${API_KEY}" "${API_URL}/${endpoint}"
}

#
# ------------------------------------------------------------
# API check
# ------------------------------------------------------------
#

check_api() {

    local pong

    pong=$(api_get "system/ping" || echo "error")

    if [[ "$pong" == *"pong"* ]]; then

        json_set "$STATUS_JSON" "api_ok" "true"

        return 0

    fi

    json_set "$STATUS_JSON" "api_ok" "false"

    return 1
}

#
# ------------------------------------------------------------
# Connection check
# ------------------------------------------------------------
#

check_connections() {

    local matrix

    matrix=$(api_get "system/connections" || echo "{}")

    local connected

    connected=$(jq -r '.connections | length > 0' <<< "$matrix" 2>/dev/null || echo false
    )

    if [[ "$connected" == "true" ]]; then

        json_set "$STATUS_JSON" "peer_connected" "true"

        return 0

    fi

    json_set "$STATUS_JSON" "peer_connected" "false"

    return 1
}

#
# ------------------------------------------------------------
# State file readers
# ------------------------------------------------------------
#

read_state_value() {

    local file="$1"
    local key="$2"

    jq -r ".${key} // \"unknown\"" "$file" 2>/dev/null || echo "unknown"
}

#
# ------------------------------------------------------------
# Overall status
# ------------------------------------------------------------
#

calculate_status() {

    local api_ok
    local peer_connected
    local handshake_status
    local verify_status
    local activate_status

    api_ok=$(jq -r '.api_ok // "false"' "$STATUS_JSON")
    peer_connected=$(jq -r '.peer_connected // "false"' "$STATUS_JSON")

    handshake_status=$(jq -r '.handshake_status // "unknown"' "$STATUS_JSON")
    verify_status=$(jq -r '.verify_status // "unknown"' "$STATUS_JSON")
    activate_status=$(jq -r '.activate_status // "unknown"' "$STATUS_JSON")

    if [[ "$api_ok" == "true"            &&
          "$peer_connected" == "true"    &&
          "$handshake_status" == "pass"  &&
          "$verify_status" == "pass"     &&
          "$activate_status" == "pass"
    ]]; then

        json_set "$STATUS_JSON" "overall_status" "healthy"

        return
    fi

    json_set "$STATUS_JSON" "overall_status" "degraded"
}

main() {

    log "Phoenix Mesh Status v2.1.1 role=${NODE_ROLE}"

    json_init "$STATUS_JSON"

    json_set "$STATUS_JSON" "timestamp" "$(date -Iseconds)"
    json_set "$STATUS_JSON" "node_role" "$NODE_ROLE"

    case "$NODE_ROLE" in

        MASTERZERO-ACTIVE|MASTERZERO-DEGRADED|MASTERZERO-RECOVER|SECONDARY-ACTIVE)

            check_api || true
            check_connections || true

            json_set \
                "$STATUS_JSON" \
                "handshake_status" \
                "$(read_state_value \
                    "${STATE_DIR}/mesh-handshake.json" \
                    "handshake_status")"

            json_set \
                "$STATUS_JSON" \
                "verify_status" \
                "$(read_state_value \
                    "${STATE_DIR}/mesh-verify.json" \
                    "verify_status")"

            json_set \
                "$STATUS_JSON" \
                "activate_status" \
                "$(read_state_value \
                    "${STATE_DIR}/mesh-activate.json" \
                    "activate_status")"

            calculate_status
            ;;

        SECONDARY-PASSIVE)

            check_api || true
            check_connections || true

            json_set \
                "$STATUS_JSON" \
                "handshake_status" \
                "$(read_state_value \
                    "${STATE_DIR}/mesh-handshake.json" \
                    "handshake_status")"

            json_set "$STATUS_JSON" "verify_status" "passive"
            json_set "$STATUS_JSON" "activate_status" "passive"

            calculate_status
            ;;

        OFFSITE)

            check_api || true
            check_connections || true

            json_set \
                "$STATUS_JSON" \
                "handshake_status" \
                "$(read_state_value \
                    "${STATE_DIR}/mesh-handshake.json" \
                    "handshake_status")"

            json_set \
                "$STATUS_JSON" \
                "verify_status" \
                "$(read_state_value \
                    "${STATE_DIR}/mesh-verify.json" \
                    "verify_status")"

            json_set "$STATUS_JSON" "activate_status" "not_applicable"

            calculate_status
            ;;

        *)

            json_set "$STATUS_JSON" "error" "invalid_node_role"
            json_set "$STATUS_JSON" "overall_status" "invalid"
            ;;

    esac

    json_finalize "$STATUS_JSON"

    /opt/semperfix/scripts/json-perms.sh "$STATUS_JSON"

    log "Mesh status written to ${STATUS_JSON}"
}

main "$@"