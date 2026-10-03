#!/usr/bin/env bash
set -euo pipefail

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
