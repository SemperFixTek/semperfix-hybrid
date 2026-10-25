#!/usr/bin/env bash
# =====================================================================
# Phoenix Automation Suite — Promote
# Version: Phoenix v2.1
# Component: phoenix-promote
# Role: Controller / Responder / Observer (role-aware)
# Refactor: 2026-10-21 — v2.0 → v2.1 role model upgrade
# Maintainer: SemperFix Automation (Bruce)
# =====================================================================

set -euo pipefail

umask 002
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

source /opt/semperfix/scripts/phoenix-core.sh
source /opt/semperfix/scripts/phoenix-json.sh
phoenix_init

PROMOTE_STATE_JSON="${STATE_DIR}/phoenix-promote.json"
FAILOVER_JSON="${STATE_DIR}/phoenix-failover.json"
LOGFILE="${LOG_DIR}/phoenix-promote.log"
PHOENIX_LOGFILE="$LOGFILE"
log() { phoenix_log_file "INFO" "$*"; }

# ---------------------------------------------------------
# Helpers
# ---------------------------------------------------------

get_failover_flag() {
    jq -r '.failover_needed // "false"' "$FAILOVER_JSON" 2>/dev/null || echo "false"
}

get_failover_reason() {
    jq -r '.reason // "none"' "$FAILOVER_JSON" 2>/dev/null || echo "none"
}

is_quic_unreachable() {
    nc -zvu "$PEER_IP" "$PEER_PORT" 2>/dev/null && echo "false" || echo "true"
}

is_mesh_degraded_local() {
    jq -r '
      (.handshake_status != "pass")
      or (.verify_status != "pass")
      or (.activate_status != "pass")
    ' "${STATE_DIR}/phoenix-supervisor.json" 2>/dev/null || echo "true"
}

load_promote_state() {
    if [[ -f "$PROMOTE_STATE_JSON" ]]; then
        jq -r '.failover_strikes // 0' "$PROMOTE_STATE_JSON" 2>/dev/null || echo 0
    else
        echo 0
    fi
}

save_promote_state() {
    local strikes="$1"
    json_init "$PROMOTE_STATE_JSON"
    json_set "$PROMOTE_STATE_JSON" "timestamp" "$(date -Iseconds)"
    json_set "$PROMOTE_STATE_JSON" "node_role" "$NODE_ROLE"
    json_set "$PROMOTE_STATE_JSON" "failover_strikes" "$strikes"
    json_finalize "$PROMOTE_STATE_JSON"
    /opt/semperfix/scripts/json-perms.sh "$PROMOTE_STATE_JSON"
}

trigger_promotion() {
    log "Promotion triggered — calling Phoenix Role Switcher"
    /opt/semperfix/scripts/phoenix-role-switch.sh SECONDARY-ACTIVE
}

# ---------------------------------------------------------
# Main
# ---------------------------------------------------------

main() {
    # Only run on passive SECONDARY
    [[ "$NODE_ROLE" != "SECONDARY-PASSIVE" && "$NODE_ROLE" != "SECONDARY" ]] && exit 0

    local failover_flag reason quic_bad mesh_bad strikes

    failover_flag=$(get_failover_flag)
    reason=$(get_failover_reason)
    quic_bad=$(is_quic_unreachable)
    mesh_bad=$(is_mesh_degraded_local)
    strikes=$(load_promote_state)

    log "Promotion check: failover=$failover_flag reason=$reason quic_bad=$quic_bad mesh_bad=$mesh_bad strikes=$strikes"

    # Policy:
    # - MASTERZERO signals failover_needed=true
    # - QUIC unreachable from SECONDARY
    # - local mesh degraded
    if [[ "$failover_flag" == "true" && "$quic_bad" == "true" && "$mesh_bad" == "true" ]]; then
        strikes=$((strikes + 1))
        log "Failover strike recorded (count=$strikes)"
    else
        strikes=0
    fi

    save_promote_state "$strikes"

    # Require 2 consecutive strikes
    if (( strikes >= 2 )); then
        trigger_promotion
    else
        log "Promotion not yet triggered (strikes<2)"
    fi
}

main "$@"
