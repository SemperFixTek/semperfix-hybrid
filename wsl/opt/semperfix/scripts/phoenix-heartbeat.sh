#!/usr/bin/env bash

# =====================================================================
# Phoenix Automation Suite — Heartbeat
# Version: Phoenix v2.2
# Component: phoenix-heartbeat
# Role: Controller / Responder / Observer
# Refactor: 2026-11-24 — v2.2 workflow architecture
# Maintainer: SemperFix Automation (Bruce)
# =====================================================================

set -euo pipefail

umask 002
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

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

    curl -s --connect-timeout 2 --max-time 5 -H "X-API-Key: \
        ${API_KEY}" "${API_URL}/system/status" || echo "{}"
}

STATUS_JSON_CACHE="$(fetch_status)"

# ------------------------------------------------------------
# Health Checks
# ------------------------------------------------------------

check_api() {

    jq -e '.myID != null' <<< "$STATUS_JSON_CACHE" >/dev/null 2>&1
}

check_syncthing_ready() {

    jq -r '.myID != null' <<< "$STATUS_JSON_CACHE" 2>/dev/null || echo "false"
}

# ------------------------------------------------------------
# Main
# ------------------------------------------------------------

main() {

    log "Phoenix Heartbeat for role: ${NODE_ROLE}"

    local api_ok="false"
    local syncthing_ready="false"

    if check_api; then
        api_ok="true"
    fi

    syncthing_ready="$(check_syncthing_ready)"

    json_init "$HEARTBEAT_FILE"

    phoenix_write_metadata "$HEARTBEAT_FILE" "heartbeat"
    json_set "$HEARTBEAT_FILE" "api_ok" "$api_ok"
    json_set "$HEARTBEAT_FILE" "syncthing_ready" "$syncthing_ready"
    json_finalize "$HEARTBEAT_FILE"

    /opt/semperfix/scripts/json-perms.sh "$HEARTBEAT_FILE"

    log "Heartbeat written to $HEARTBEAT_FILE"
}

main "$@"