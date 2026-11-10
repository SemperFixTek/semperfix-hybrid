#!/usr/bin/env bash

# =====================================================================
# Phoenix Automation Suite — QUIC Responder
# Version: Phoenix v2.1
# Component: quic-responder
# Role: Responder-only (SECONDARY-PASSIVE)
# Refactor: 2026-11-09 — v2.0 → v2.1 role model upgrade
# Maintainer: SemperFix Automation (Bruce)
# Audit 2026-11-09
# =====================================================================

set -euo pipefail

umask 002
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

# shellcheck disable=SC1091
source /opt/semperfix/scripts/phoenix-core.sh

phoenix_init

case "$NODE_ROLE" in
    SECONDARY-PASSIVE)
        ;;
    *)
        exit 0
        ;;
esac

PORT="${PHOENIX_QUIC_PORT}"

LOGFILE="${LOG_DIR}/phoenix-quic-responder.log"
HANDLER="/opt/semperfix/scripts/phoenix-quic-handler.sh"

# shellcheck disable=SC2034
PHOENIX_LOGFILE="$LOGFILE"

phoenix_log_file "INFO" "Phoenix QUIC Responder starting on UDP port ${PORT}"

exec socat -u UDP-RECVFROM:"${PORT}",fork SYSTEM:"${HANDLER}" 2>>"${LOGFILE}"