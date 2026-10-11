#!/usr/bin/env bash
set -euo pipefail

source /opt/semperfix/scripts/phoenix-core.sh
source /opt/semperfix/scripts/phoenix-json.sh
phoenix_init

STATE_DIR="/var/lib/semperfix/state"
LOG="/opt/semperfix/logs/mesh-listener.log"
STATUS_JSON="$STATE_DIR/mesh-status.json"

SYNCTHING_API="${API_URL}/system/status"
QUIC_TARGET="${PEER_IP}:${PEER_PORT}"

log() {
    echo "[$(date -Iseconds)] [LISTENER] $*" | tee -a "$LOG"
}

write_state() {
    cat <<EOF > "$STATUS_JSON"
{
    "Timestamp": "$(date -Iseconds)",
    "NodeRole": "${NODE_ROLE}",
    "SyncthingReachable": "$1",
    "QuicReachable": "$2"
}
EOF
}

check_syncthing() {
    if curl -s --max-time 2 \
        -H "X-API-Key: ${API_KEY}" \
        "$SYNCTHING_API" >/dev/null; then
        echo "true"
    else
        echo "false"
    fi
}

check_quic() {
    if timeout 2 bash -c "</dev/tcp/${QUIC_TARGET%:*}/${QUIC_TARGET#*:}" 2>/dev/null; then
        echo "true"
    else
        echo "false"
    fi
}

if [[ "$NODE_ROLE" != "MASTERZERO" ]]; then
    log "Mesh listener disabled for role: $NODE_ROLE"
    exit 0
fi

log "Phoenix Mesh Listener starting (${NODE_ROLE})"

while true; do
    syncthing_ok=$(check_syncthing)
    quic_ok=$(check_quic)

    log "Syncthing=$syncthing_ok  QUIC=$quic_ok"

    write_state "$syncthing_ok" "$quic_ok"

    sleep 5
done
