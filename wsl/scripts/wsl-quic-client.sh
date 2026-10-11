#!/usr/bin/env bash
set -euo pipefail

# Phoenix v2 Core + JSON Loader
source /opt/semperfix/scripts/phoenix-core.sh
source /opt/semperfix/scripts/phoenix-json.sh
phoenix_init

STATE_DIR="/var/lib/semperfix/state"
LOG="/opt/semperfix/logs/quic-client.log"
STATUS_JSON="$STATE_DIR/quic-client-status.json"

# QUIC target derived from phoenix.json
QUIC_TARGET="${PEER_IP}:${PHOENIX_QUIC_PORT}"

log() {
    echo "[$(date -Iseconds)] [QUIC-CLIENT] $*" | tee -a "$LOG"
}

write_state() {
    cat <<EOF > "$STATUS_JSON"
{
    "Timestamp": "$(date -Iseconds)",
    "NodeRole": "${NODE_ROLE}",
    "QuicReachable": "$1",
    "LatencyMs": "$2"
}
EOF
}

# QUIC reachability test using /dev/tcp
check_quic() {
    if timeout 2 bash -c "</dev/tcp/${QUIC_TARGET%:*}/${QUIC_TARGET#*:}" 2>/dev/null; then
        echo "true"
    else
        echo "false"
    fi
}

# QUIC latency measurement
measure_latency() {
    local start end
    start=$(date +%s%3N)

    if timeout 2 bash -c "</dev/tcp/${QUIC_TARGET%:*}/${QUIC_TARGET#*:}" 2>/dev/null; then
        end=$(date +%s%3N)
        echo $((end - start))
    else
        echo "-1"
    fi
}

log "Phoenix QUIC Client starting (${NODE_ROLE})"
log "Target: ${QUIC_TARGET}"

while true; do
    quic_ok=$(check_quic)
    latency=$(measure_latency)

    log "QUIC=$quic_ok  Latency=${latency}ms"

    write_state "$quic_ok" "$latency"

    sleep 5
done
