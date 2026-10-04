#!/usr/bin/env bash
set -euo pipefail

# Phoenix v2 Standard Environment Header
umask 002

# Ensure consistent locale + predictable JSON behavior
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

# Ensure logs and state directories exist
mkdir -p /var/lib/semperfix/state
mkdir -p /opt/semperfix/logs

# Safety: prevent Windows CRLF issues
dos2unix "$0" 2>/dev/null || true

# Load Phoenix core + config
source /opt/semperfix/scripts/phoenix-core.sh
phoenix_load_config

PORT="${PHOENIX_QUIC_PORT:-22001}"
LOGFILE="/opt/semperfix/logs/phoenix-quic-responder.log"

echo "[INFO] Phoenix QUIC Responder starting on UDP port ${PORT}" >> "$LOGFILE"

socat -u UDP-RECVFROM:$PORT,fork SYSTEM:'
    echo "[INFO] Received QUIC probe from $SOCAT_PEERADDR" >> '"$LOGFILE"'
    echo ack | socat -u - UDP-SENDTO:$SOCAT_PEERADDR:'"$PORT"' >> '"$LOGFILE"'
' 2>>"$LOGFILE"
