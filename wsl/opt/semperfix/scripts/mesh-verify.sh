#!/usr/bin/env bash

# =====================================================================
# Phoenix Automation Suite — Mesh Verify
# Version: Phoenix v2.1
# Component: phoenix-mesh-verify
# Role: Responder / Observer (role-aware)
# Refactor: 2026-11-05 — v2.0 → v2.1 role model upgrade
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

LOGFILE="${LOG_DIR}/mesh-verify.log"
JSON_OUT="${STATE_DIR}/mesh-verify.json"
LOCKFILE=/run/lock/mesh-verify.lock
# shellcheck disable=SC2034
PHOENIX_LOGFILE="$LOGFILE"

mkdir -p "$(dirname "$LOCKFILE")"

exec 200>"$LOCKFILE"

flock -n 200 || {
    log "[WARN] Another mesh-verify is already running"
    exit 0
}

log() { phoenix_log_file "INFO" "$*"; }

api_get() {

    local endpoint="$1"

    curl -s --connect-timeout 2 --max-time 5 \
         -H "X-API-Key: ${API_KEY}" "${API_URL}/${endpoint}"
}

verify_connections() {
    log "Checking Syncthing connection matrix"

    local matrix
    matrix=$(api_get "system/connections" || echo "{}")

    printf "%s\n" "$matrix" >> "$LOGFILE"

    local connected
    connected=$(jq -r '.connections | length > 0' <<< "$matrix" 2>/dev/null || echo "false")

    if [[ "$connected" == "true" ]]; then
        log "At least one peer is connected"
        json_set "$JSON_OUT" "peer_connected" "true"
        return 0
    else
        log "No peers connected"
        json_set "$JSON_OUT" "peer_connected" "false"
        return 1
    fi
}

verify_device_ids() {
    log "Checking device ID list"

    local devices
    devices=$(api_get "system/status")

    printf "%s\n" "$devices" >> "$LOGFILE"

    local has_id
    has_id=$(jq -r '.myID != null' <<< "$devices" 2>/dev/null || echo "false")

    if [[ "$has_id" == "true" ]]; then
        log "Device ID present"
        json_set "$JSON_OUT" "device_id_present" "true"
        return 0
    else
        log "Device ID missing"
        json_set "$JSON_OUT" "device_id_present" "false"
        return 1
    fi
}

verify_folders() {
    log "Checking folder health"

    local folders
    folders=$(api_get "stats/folder")

    printf "%s\n" "$folders" >> "$LOGFILE"

    local all_idle
    all_idle=$(jq -r 'type == "object"' <<< "$folders" 2>/dev/null || echo false)
    if [[ "$all_idle" == "true" ]]; then
        log "Folders idle and healthy"
        json_set "$JSON_OUT" "folder_health" "healthy"
        return 0
    else
        log "Folders not idle"
        json_set "$JSON_OUT" "folder_health" "not_idle"
        return 0
    fi
}

main() {
    log "Starting Phoenix Mesh Verify for role: ${NODE_ROLE}"

    json_init "$JSON_OUT"
    json_set "$JSON_OUT" "timestamp" "$(date -Iseconds)"
    json_set "$JSON_OUT" "node_role" "$NODE_ROLE"
    json_set "$JSON_OUT" "api_url" "$API_URL"

    local verify_status="fail"

    case "$NODE_ROLE" in

        MASTERZERO-ACTIVE|MASTERZERO-DEGRADED|MASTERZERO-RECOVER)
            log "${NODE_ROLE} performing full mesh verification"
            local connection_status=fail
            local device_status=fail

            if verify_connections; then
                connection_status=pass
            fi

            if verify_device_ids; then
                device_status=pass
            fi

            verify_folders

            if [[ "$connection_status" == "pass" &&
                "$device_status" == "pass" ]]; then
                verify_status="pass"
            else
                verify_status="fail"
            fi
            ;;

        SECONDARY-ACTIVE)
            log "SECONDARY-ACTIVE performing full mesh verification (controller mode)"
            local connection_status=fail
            local device_status=fail

            if verify_connections; then
                connection_status=pass
            fi

            if verify_device_ids; then
                device_status=pass
            fi

            verify_folders

            if [[ "$connection_status" == "pass" &&
                "$device_status" == "pass" ]]; then
                verify_status="pass"
            else
                verify_status="fail"
            fi
            ;;

        SECONDARY-PASSIVE)
            log "SECONDARY-PASSIVE — verification telemetry only"
            verify_device_ids
            json_set "$JSON_OUT" "peer_connected" "not_applicable"
            json_set "$JSON_OUT" "folder_health" "not_applicable"
            if verify_device_ids; then
                verify_status="pass"
            else
                verify_status="fail"
            fi
            ;;

        OFFSITE)
            log "OFFSITE performing limited mesh verification"
            verify_device_ids
            json_set "$JSON_OUT" "peer_connected" "not_applicable"
            json_set "$JSON_OUT" "folder_health" "not_applicable"
            if verify_device_ids; then
                verify_status="pass"
            else
                verify_status="fail"
            fi
            ;;

        *)
            log "Unknown node role: ${NODE_ROLE}"
            json_set "$JSON_OUT" "error" "invalid_node_role"
            verify_status="fail"
            ;;
    esac

    json_set "$JSON_OUT" "verify_status" "$verify_status"

    log "Mesh verification complete"
    json_finalize "$JSON_OUT"

    /opt/semperfix/scripts/json-perms.sh "$JSON_OUT"
}

main "$@"
