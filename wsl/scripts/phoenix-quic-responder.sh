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
phoenix_init

# --- ROLE GUARD: SECONDARY ONLY ---
if [[ "$NODE_ROLE" != "SECONDARY" ]]; then
    echo "[INFO] QUIC responder disabled for role: ${NODE_ROLE}"
    exit 0
fi

PORT="${PHOENIX_QUIC_PORT:-22001}"
LOGFILE="${LOG_DIR}/phoenix-quic-responder.log"

PHOENIX_LOGFILE="$LOGFILE"
log() { phoenix_log_file "INFO" "$*"; }

log "Phoenix QUIC Responder starting on UDP port ${PORT}"

# --- Handler script for clean logging ---
HANDLER="/opt/semperfix/scripts/quic-handler.sh"

cat <<'EOF' > "$HANDLER"
#!/usr/bin/env bash
set -euo pipefail

LOGFILE="/opt/semperfix/logs/quic-handler.log"
PEER="$SOCAT_PEERADDR"

echo "[INFO] Received QUIC probe from ${PEER}" >> "$LOGFILE"
echo ack | socat -u - UDP-SENDTO:${PEER}:22001 >> "$LOGFILE" 2>&1
EOF

chmod +x "$HANDLER"

# --- Main socat listener ---
socat -u UDP-RECVFROM:$PORT,fork SYSTEM:"$HANDLER" 2>>"$LOGFILE"
