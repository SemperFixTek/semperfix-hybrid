#!/usr/bin/env bash
# =====================================================================
# Phoenix Automation Suite — QUIC Responder
# Version: Phoenix v2.1
# Component: quic-responder
# Role: Responder-only (SECONDARY-PASSIVE)
# Refactor: 2026-10-21 — v2.0 → v2.1 role model upgrade
# Maintainer: SemperFix Automation (Bruce)
# =====================================================================

set -euo pipefail

umask 002
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

dos2unix "$0" 2>/dev/null || true

source /opt/semperfix/scripts/phoenix-core.sh
phoenix_init

# --- ROLE GUARD: Phoenix v2.1 ---
case "$NODE_ROLE" in
    SECONDARY-PASSIVE)
        phoenix_log_file "INFO" "QUIC responder enabled for role: ${NODE_ROLE}"
        ;;
    *)
        phoenix_log_file "INFO" "QUIC responder disabled for role: ${NODE_ROLE}"
        exit 0
        ;;
esac

PORT="${PHOENIX_QUIC_PORT}"
LOGFILE="${LOG_DIR}/phoenix-quic-responder.log"

PHOENIX_LOGFILE="$LOGFILE"
log() { phoenix_log_file "INFO" "$*"; }

log "Phoenix QUIC Responder starting on UDP port ${PORT}"

# --- Handler script for clean logging ---
HANDLER="/opt/semperfix/scripts/quic-handler.sh"

cat > "$HANDLER" <<EOF
#!/usr/bin/env bash
# Phoenix v2.1 — QUIC Handler
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
