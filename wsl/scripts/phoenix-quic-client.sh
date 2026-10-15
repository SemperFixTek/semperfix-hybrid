#!/usr/bin/env bash
set -euo pipefail

umask 002
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

# Normalize line endings
dos2unix "$0" 2>/dev/null || true

# Load Phoenix core + JSON helpers
source /opt/semperfix/scripts/phoenix-core.sh
source /opt/semperfix/scripts/phoenix-json.sh
phoenix_init

LOGFILE="${LOG_DIR}/quic-client.log"
STATUS_JSON="${STATE_DIR}/quic-client-status.json"

PHOENIX_LOGFILE="$LOGFILE"
log() { phoenix_log_file "INFO" "$*"; }

# --- ROLE GUARD: MASTERZERO ONLY ---
if [[ "$NODE_ROLE" != "MASTERZERO" ]]; then
    log "QUIC client disabled for role: ${NODE_ROLE}"
    exit 0
fi

QUIC_IP="${PEER_IP}"
QUIC_PORT="${PHOENIX_QUIC_PORT}"

check_quic() {
    if echo "probe" | nc -u -w1 "${QUIC_IP}" "${QUIC_PORT}" &>/dev/null; then
        echo "true"
    else
        echo "false"
    fi
}

measure_latency() {
    local start end
    start=$(date +%s%3N)

    if echo "probe" | nc -u -w1 "${QUIC_IP}" "${QUIC_PORT}" &>/dev/null; then
        end=$(date +%s%3N)
        echo $((end - start))
    else
        echo "-1"
    fi
}

write_state() {
    json_init "$STATUS_JSON"
    json_set "$STATUS_JSON" "timestamp" "$(date -Iseconds)"
    json_set "$STATUS_JSON" "node_role" "$NODE_ROLE"
    json_set "$STATUS_JSON" "quic_reachable" "$1"
    json_set "$STATUS_JSON" "latency_ms" "$2"
    json_finalize "$STATUS_JSON"

    # Fix permissions for Syncthing + Windows
    /opt/semperfix/scripts/json-perms.sh "$STATUS_JSON"
}

log "Phoenix QUIC Client starting (${NODE_ROLE})"
log "Target: ${QUIC_IP}:${QUIC_PORT}"

while true; do
    quic_ok=$(check_quic)
    latency=$(measure_latency)

    log "QUIC=${quic_ok}  Latency=${latency}ms"

    write_state "$quic_ok" "$latency"

    sleep 5
done
