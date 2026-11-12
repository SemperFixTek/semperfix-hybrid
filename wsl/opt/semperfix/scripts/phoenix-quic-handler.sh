#!/usr/bin/env bash

# =====================================================================
# Phoenix Automation Suite — QUIC Handler
# Version: Phoenix v2.1.1
# Component: phoenix-quic-handler
# Role: Responder-only (SECONDARY-PASSIVE)
# Refactor: 2026-11-12 — v2.1.0 → v2.1.1 role model upgrade
# Maintainer: SemperFix Automation (Bruce)
# Audit 2026-11-09
# =====================================================================

set -euo pipefail

umask 002
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

# shellcheck disable=SC1091
source /opt/semperfix/scripts/phoenix-core.sh

LOGFILE="${LOG_DIR}/quic-handler.log"
# PORT="${PHOENIX_QUIC_PORT}"

# shellcheck disable=SC2034
PHOENIX_LOGFILE="$LOGFILE"

peer_addr="${SOCAT_PEERADDR:-unknown}"
peer_port="${SOCAT_PEERPORT:-0}"

#
# Optional:
# Rate-limit or disable success logging later if desired.
#

phoenix_log_file "INFO" "QUIC probe received from ${peer_addr}:${peer_port}"

printf 'ack\n' | socat -u - UDP-SENDTO:${peer_addr}:${peer_port} >/dev/null 2>&1

phoenix_log_file "INFO" "Sending ACK to ${peer_addr}:${peer_port}"
phoenix_log_file "INFO" "peer=${SOCAT_PEERADDR:-none} port=${SOCAT_PEERPORT:-none}"

exit 0
