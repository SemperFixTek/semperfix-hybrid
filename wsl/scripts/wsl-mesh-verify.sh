#!/usr/bin/env bash
set -euo pipefail

umask 002
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

STATE_DIR="/var/lib/semperfix/state"
LOG_DIR="/opt/semperfix/logs"

mkdir -p "$STATE_DIR" "$LOG_DIR"
dos2unix "$0" 2>/dev/null || true

source /opt/semperfix/scripts/phoenix-core.sh
source /opt/semperfix/scripts/phoenix-json.sh
phoenix_init

LOGFILE="${LOG_DIR}/mesh-verify.log"
JSON_OUT="${STATE_DIR}/mesh-verify.json"

PHOENIX_LOGFILE="$LOGFILE"
log() { phoenix_log_file "INFO" "$*"; }

verify_connections() {
    log "Checking Syncthing connection matrix"

    local matrix
    matrix=$(curl -s -H "X-API-Key: ${API_KEY}" "${API_URL}/system/connections")

    printf "%s\n" "$matrix" >> "$LOGFILE"

    if [[ "$matrix" == *"connected\": true"* ]]; then
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
    devices=$(curl -s -H "X-API-Key: ${API_KEY}" "${API_URL}/system/status")

    printf "%s\n" "$devices" >> "$LOGFILE"

    if [[ "$devices" == *"myID"* ]]; then
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
    folders=$(curl -s -H "X-API-Key: ${API_KEY}" "${API_URL}/stats/folder")

    printf "%s\n" "$folders" >> "$LOGFILE"

    if [[ "$folders" == *"state\": \"idle\""* ]]; then
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

    case "$NODE_ROLE" in

        MASTERZERO|SECONDARY)
            log "${NODE_ROLE} performing full mesh verification"
            verify_connections
            verify_device_ids
            verify_folders
            ;;

        OFFSITE)
            log "OFFSITE performing limited mesh verification"
            verify_device_ids
            json_set "$JSON_OUT" "peer_connected" "not_applicable"
            json_set "$JSON_OUT" "folder_health" "not_applicable"
            ;;

        *)
            log "Unknown node role: ${NODE_ROLE}"
            json_set "$JSON_OUT" "error" "invalid_node_role"
            ;;
    esac

    log "Mesh verification complete"
    json_finalize "$JSON_OUT"
}

main "$@"
