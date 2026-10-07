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

LOGFILE="/opt/semperfix/logs/mesh-verify.log"
JSON_OUT="/opt/semperfix/logs/mesh-verify.json"

# ---------- Connection Matrix ----------
verify_connections() {
    local api_url="$1"
    local api_key="$2"

    log "INFO" "Checking Syncthing connection matrix" "$BLUE"

    local matrix
    matrix=$(curl -s -H "X-API-Key: ${api_key}" "${api_url}/system/connections")

    echo "$matrix" >> "$LOGFILE"

    if [[ "$matrix" == *"connected\": true"* ]]; then
        log "PASS" "At least one peer is connected" "$GREEN"
        json_set "$JSON_OUT" "peer_connected" "true"
        return 0
    else
        log "FAIL" "No peers connected" "$RED"
        json_set "$JSON_OUT" "peer_connected" "false"
        return 1
    fi
}

# ---------- Device ID Check ----------
verify_device_ids() {
    local api_url="$1"
    local api_key="$2"

    log "INFO" "Checking device ID list" "$BLUE"

    local devices
    devices=$(curl -s -H "X-API-Key: ${api_key}" "${api_url}/system/status")

    echo "$devices" >> "$LOGFILE"

    if [[ "$devices" == *"myID"* ]]; then
        log "PASS" "Device ID present" "$GREEN"
        json_set "$JSON_OUT" "device_id_present" "true"
        return 0
    else
        log "FAIL" "Device ID missing" "$RED"
        json_set "$JSON_OUT" "device_id_present" "false"
        return 1
    fi
}

# ---------- Folder Health ----------
verify_folders() {
    local api_url="$1"
    local api_key="$2"

    log "INFO" "Checking folder health" "$BLUE"

    local folders
    folders=$(curl -s -H "X-API-Key: ${api_key}" "${api_url}/stats/folder")

    echo "$folders" >> "$LOGFILE"

    if [[ "$folders" == *"state\": \"idle\""* ]]; then
        log "PASS" "Folders idle and healthy" "$GREEN"
        json_set "$JSON_OUT" "folder_health" "healthy"
        return 0
    else
        log "WARN" "Folders not idle" "$YELLOW"
        json_set "$JSON_OUT" "folder_health" "not_idle"
        return 0   # correct: not_idle is not a failure
    fi
}

# ---------- Main ----------
main() {
    mkdir -p /opt/semperfix/logs
    : > "$LOGFILE"

    json_init "$JSON_OUT"

    log "INFO" "Starting Phoenix Mesh Verify for role: ${NODE_ROLE}" "$YELLOW"

    json_set "$JSON_OUT" "timestamp" "$(date -Iseconds)"
    json_set "$JSON_OUT" "node_role" "$NODE_ROLE"
    json_set "$JSON_OUT" "api_url" "$API_URL"

    case "$NODE_ROLE" in

        MASTERZERO)
            log "INFO" "MASTERZERO performing full mesh verification" "$BLUE"

            verify_connections "$API_URL" "$API_KEY"
            verify_device_ids "$API_URL" "$API_KEY"
            verify_folders "$API_URL" "$API_KEY"
            ;;

        SECONDARY)
            log "INFO" "SECONDARY performing full mesh verification" "$BLUE"

            verify_connections "$API_URL" "$API_KEY"
            verify_device_ids "$API_URL" "$API_KEY"
            verify_folders "$API_URL" "$API_KEY"
            ;;

        OFFSITE)
            log "INFO" "OFFSITE performing limited mesh verification" "$BLUE"

            # OFFSITE does NOT participate in QUIC mesh or folder sync
            verify_device_ids "$API_URL" "$API_KEY"

            json_set "$JSON_OUT" "peer_connected" "not_applicable"
            json_set "$JSON_OUT" "folder_health" "not_applicable"
            ;;

        *)
            log "FAIL" "Unknown node role: ${NODE_ROLE}" "$RED"
            json_set "$JSON_OUT" "error" "invalid_node_role"
            ;;
    esac

    log "INFO" "Mesh verification complete" "$GREEN"
    json_finalize "$JSON_OUT"
}


main "$@"
