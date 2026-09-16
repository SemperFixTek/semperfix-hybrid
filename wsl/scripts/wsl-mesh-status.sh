#!/usr/bin/env bash
set -euo pipefail

STATUS_FILE="/opt/semperfix/state/mesh-status.json"
LOGFILE="/opt/semperfix/logs/mesh-status.log"

API_URL=$(jq -r '.api_url' /opt/semperfix/logs/phoenix-supervisor.json)
API_KEY=$(jq -r '.api_key' /opt/semperfix/logs/phoenix-supervisor.json)

log() {
    echo "[${1}] ${2}" | tee -a "$LOGFILE"
}

main() {
    mkdir -p /opt/semperfix/state
    mkdir -p /opt/semperfix/logs
    : > "$LOGFILE"

    log "INFO" "Mesh Status (v2)"

    # Query Syncthing API
    local st_json
    st_json=$(curl -s -H "X-API-Key: $API_KEY" "$API_URL/rest/system/status" || echo "{}")

    # Query connections
    local conn_json
    conn_json=$(curl -s -H "X-API-Key: $API_KEY" "$API_URL/rest/system/connections" || echo "{}")

    # Query folder health
    local folder_json
    folder_json=$(curl -s -H "X-API-Key: $API_KEY" "$API_URL/rest/db/status?folder=assets" || echo "{}")

    # Extract fields
    local device_count connected_count
    device_count=$(echo "$conn_json" | jq '.connections | length')
    connected_count=$(echo "$conn_json" | jq '[.connections[] | select(.connected == true)] | length')

    local folder_state
    folder_state=$(echo "$folder_json" | jq -r '.state // "unknown"')

    # QUIC check
    local quic_ok="false"
    if nc -u -w1 10.10.10.2 22000 >/dev/null 2>&1; then
        quic_ok="true"
    fi

    # Build JSON
    {
        echo "{"
        echo "  \"timestamp\": \"$(date -Iseconds)\","
        echo "  \"device_count\": $device_count,"
        echo "  \"connected\": $connected_count,"
        echo "  \"folder_state\": \"$folder_state\","
        echo "  \"quic_ok\": \"$quic_ok\""
        echo "}"
    } > "$STATUS_FILE"

    log "INFO" "Mesh status written to $STATUS_FILE"
}

main "$@"
