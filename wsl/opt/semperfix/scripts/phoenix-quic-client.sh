#!/usr/bin/env bash

# =====================================================================
# Phoenix Automation Suite — Quic Client
# Version: Phoenix v2.1
# Component: phoenix-quic-client
# Role: Controller-only (MASTERZERO-* and SECONDARY-ACTIVE)
# Refactor: 2026-10-21 — v2.0 → v2.1 role model upgrade
# Maintainer: SemperFix Automation (Bruce)
# =====================================================================

set -euo pipefail

umask 002
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

# dos2unix "$0" >/dev/null 2>&1 || true

# shellcheck disable=SC1091
source /opt/semperfix/scripts/phoenix-core.sh
# shellcheck disable=SC1091
source /opt/semperfix/scripts/phoenix-json.sh

phoenix_init

LOGFILE="${LOG_DIR}/quic-client.log"
STATUS_JSON="${STATE_DIR}/quic-client-status.json"

# shellcheck disable=SC2034
PHOENIX_LOGFILE="$LOGFILE"

log() {
    phoenix_log_file "INFO" "$*"
}

# ------------------------------------------------------------
# Role Guard
# ------------------------------------------------------------

case "$NODE_ROLE" in
    MASTERZERO-ACTIVE|MASTERZERO-DEGRADED|MASTERZERO-RECOVER|SECONDARY-ACTIVE)

        log "QUIC client enabled for role: ${NODE_ROLE}"
        ;;

    *)

        log "QUIC client disabled for role: ${NODE_ROLE}"
        exit 0
        ;;
esac

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------

QUIC_IP="${PEER_IP}"
QUIC_PORT="${PHOENIX_QUIC_PORT}"

# ------------------------------------------------------------
# Probe
# ------------------------------------------------------------

probe_quic() {

    local start
    local end
    local response

    start=$(date +%s%3N)

    response=$(
    printf 'probe\n' | socat -T2 STDIO UDP-CONNECT:"${QUIC_IP}":"${QUIC_PORT}"
)

    end=$(date +%s%3N)

    response=$(echo "$response" | tr -d '\r\n')

    if [[ "$response" == "ack" ]]; then

        echo "true:$((end - start))"

    else

        echo "false:-1"

    fi
}

# ------------------------------------------------------------
# State Writer
# ------------------------------------------------------------

write_state() {

    local reachable="$1"
    local latency="$2"

    json_init "$STATUS_JSON"

    json_set "$STATUS_JSON" "timestamp" "$(date -Iseconds)"
    json_set "$STATUS_JSON" "node_role" "$NODE_ROLE"

    json_set "$STATUS_JSON" "quic_reachable" "$reachable"
    json_set "$STATUS_JSON" "latency_ms" "$latency"

    json_finalize "$STATUS_JSON"

    /opt/semperfix/scripts/json-perms.sh "$STATUS_JSON"
}

# ------------------------------------------------------------
# Main
# ------------------------------------------------------------

log "Phoenix QUIC Client running once (${NODE_ROLE})"
log "Target: ${QUIC_IP}:${QUIC_PORT}"

result="$(probe_quic)"

quic_ok="${result%%:*}"
latency="${result##*:}"

log "QUIC=${quic_ok} Latency=${latency}ms"

write_state "$quic_ok" "$latency"

exit 0