#!/usr/bin/env bash
set -euo pipefail

STATUS_FILE="/opt/semperfix/logs/phoenix-supervisor.json"
OUT_FILE="/opt/semperfix/state/phoenix-status.json"
LOGFILE="/opt/semperfix/logs/phoenix-status-write.log"

log() {
    echo "[${1}] ${2}" >> "$LOGFILE"
    echo "[${1}] ${2}"
}

main() {
    mkdir -p /opt/semperfix/state
    mkdir -p /opt/semperfix/logs
    : > "$LOGFILE"

    log "INFO" "Phoenix Status Write (v2)"

    if [[ ! -f "$STATUS_FILE" ]]; then
        log "FAIL" "Supervisor JSON missing"
        exit 0
    fi

    # Read supervisor results
    local handshake verify activate
    handshake=$(jq -r '.handshake_status' "$STATUS_FILE")
    verify=$(jq -r '.verify_status' "$STATUS_FILE")
    activate=$(jq -r '.activate_status' "$STATUS_FILE")

    # Compute mesh_ok
    local mesh_ok="false"
    if [[ "$handshake" == "pass" && "$verify" == "pass" && "$activate" == "pass" ]]; then
        mesh_ok="true"
    fi

    # Build v2 status JSON
    {
        echo "{"
        echo "  \"timestamp\": \"$(date -Iseconds)\","
        echo "  \"node_role\": \"$(jq -r '.node_role' "$STATUS_FILE")\","
        echo "  \"api_url\": \"$(jq -r '.api_url' "$STATUS_FILE")\","
        echo "  \"peer_target\": \"$(jq -r '.peer_target' "$STATUS_FILE")\","
        echo "  \"health\": {"
        echo "    \"api_ok\": \"$(jq -r '.api_ok // "unknown"' "$STATUS_FILE")\","
        echo "    \"peer_connected\": \"$(jq -r '.peer_connected // "unknown"' "$STATUS_FILE")\","
        echo "    \"syncthing_ready\": \"$(jq -r '.syncthing_ready // "unknown"' "$STATUS_FILE")\","
        echo "    \"quic_ok\": \"$(jq -r '.quic_ok // "unknown"' "$STATUS_FILE")\","
        echo "    \"mesh_ok\": \"$mesh_ok\""
        echo "  }"
        echo "}"
    } > "$OUT_FILE"

    log "INFO" "Phoenix status written to $OUT_FILE"
}

main "$@"
