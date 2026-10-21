#!/usr/bin/env bash
set -euo pipefail

umask 002
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

# Normalize line endings
dos2unix "$0" 2>/dev/null || true

# Load Phoenix core
source /opt/semperfix/scripts/phoenix-core.sh
phoenix_init

# --- ROLE GUARD: SECONDARY ONLY ---
if [[ "$NODE_ROLE" != "SECONDARY" ]]; then
    phoenix_log_file "INFO" "QUIC responder disabled for role: ${NODE_ROLE}"
    exit 0
fi

PORT="${PHOENIX_QUIC_PORT}"
LOGFILE="${LOG_DIR}/phoenix-quic-responder.log"

PHOENIX_LOGFILE="$LOGFILE"
log() { phoenix_log_file "INFO" "$*"; }

log "Phoenix QUIC Responder starting on UDP port ${PORT}"

# --- Handler script for clean logging ---
HANDLER="/opt/semperfix/scripts/quic-handler.sh"

cat > "$HANDLER" <<EOF
#!/usr/bin/env bash
set -euo pipefail

LOGFILE="${LOG_DIR}/quic-handler.log"
PEER="\$SOCAT_PEERADDR"

echo "[INFO] Received QUIC probe from \${PEER}" >> "\$LOGFILE"
echo ack | socat -u - UDP-SENDTO:\${PEER}:${PORT} >> "\$LOGFILE" 2>&1
EOF

chmod +x "$HANDLER"

# --- Main socat listener ---
socat -u UDP-RECVFROM:$PORT,fork SYSTEM:"$HANDLER" 2>>"$LOGFILE"

# Fix permissions for Syncthing + Windows
chown root:semperfix "$LOGFILE"
chmod 664 "$LOGFILE"
