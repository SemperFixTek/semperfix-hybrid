#!/usr/bin/env bash
set -euo pipefail

source /opt/semperfix/scripts/phoenix-core.sh
source /opt/semperfix/scripts/phoenix-json.sh
phoenix_load_config

LOGFILE="/opt/semperfix/logs/mesh-verify.log"
JSON_OUT="/opt/semperfix/logs/mesh-verify.json"

RED="\033[0;31m"; GREEN="\033[0;32m"; YELLOW="\033[1;33m"; BLUE="\033[0;34m"; NC="\033[0m"

log() {
    echo -e "${3}[${1}]${NC} ${2}"
    echo "[${1}] ${2}" >> "$LOGFILE"
}

check_connections() {
    log "INFO" "Checking Syncthing connection matrix" "$BLUE"
    local matrix
    matrix=$(curl -s -H "X-API-Key: $API_KEY" "$API_URL/system/connections")
    echo "$matrix" >> "$LOGFILE"

    if [[ "$matrix" == *"connected\": true"* ]]; then
        log "PASS" "At least one peer is connected" "$GREEN"
        json_add "$JSON_OUT" "peer_connected" "true"
    else
        log "FAIL" "No peers connected" "$RED"
        json_add "$JSON_OUT" "peer_connected" "false"
    fi
}

check_device_ids() {
    log "INFO" "Checking device ID list" "$BLUE"
    local devices
    devices=$(curl -s -H "X-API-Key: $API_KEY" "$API_URL/system/status")
    echo "$devices" >> "$LOGFILE"

    if [[ "$devices" == *"$LOCAL_DEVICE_ID"* ]]; then
        log "PASS" "Device ID present" "$GREEN"
        json_add "$JSON_OUT" "device_id_ok" "true"
    else
        log "FAIL" "Device ID missing" "$RED"
        json_add "$JSON_OUT" "device_id_ok" "false"
    fi
}

check_folder_health() {
    log "INFO" "Checking folder health" "$BLUE"
    local folders
    folders=$(curl -s -H "X-API-Key: $API_KEY" "$API_URL/system/status")
    echo "$folders" >> "$LOGFILE"

    if [[ "$folders" == *"state\": \"idle\""* ]]; then
        log "PASS" "Folders idle" "$GREEN"
        json_add "$JSON_OUT" "folders_idle" "true"
    else
        log "WARN" "Folders not idle" "$YELLOW"
        json_add "$JSON_OUT" "folders_idle" "false"
    fi
}

main() {
    mkdir -p /opt/semperfix/logs
    : > "$LOGFILE"

    json_init "$JSON_OUT"
    log "INFO" "Starting Phoenix Mesh Verify" "$YELLOW"

    json_add "$JSON_OUT" "timestamp" "$(date -Iseconds)"
    json_add "$JSON_OUT" "node_role" "$NODE_ROLE"

    check_connections
    check_device_ids
    check_folder_health

    log "INFO" "Mesh verification complete" "$GREEN"
    json_close "$JSON_OUT"
}

main "$@"
