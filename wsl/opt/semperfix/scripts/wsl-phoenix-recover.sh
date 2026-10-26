#!/usr/bin/env bash
# =====================================================================
# Phoenix Automation Suite — Recover
# Version: Phoenix v2.1
# Component: phoenix-recover
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

RECOVER_STATE_JSON="${STATE_DIR}/phoenix-recover.json"
RECOVERY_JSON="${STATE_DIR}/phoenix-supervisor.json"
LOGFILE="${LOG_DIR}/phoenix-recover.log"
PHOENIX_LOGFILE="$LOGFILE"

log() { phoenix_log_file "INFO" "$*"; }

# ---------------------------------------------------------
# Helpers
# ---------------------------------------------------------

RECOVERY_STATUS=$(jq -r '.recovery_status// false' "${RECOVERY_JSON}")

is_quic_unreachable() {
    nc -zvu "$PEER_IP" "$PEER_PORT" 2>/dev/null && echo "false" || echo "true"
}

is_mesh_unstable_local() {
    jq -r '
      (.handshake_status != "pass")
      or (.verify_status != "pass")
      or (.activate_status != "pass")
    ' "${STATE_DIR}/phoenix-supervisor.json" 2>/dev/null || echo "true"
}

load_recover_state() {
    if [[ -f "$RECOVER_STATE_JSON" ]]; then
        jq -r '.Recovery_strikes // 0' "$RECOVER_STATE_JSON" 2>/dev/null || echo 0
    else
        echo 0
    fi
}

save_recover_state() {
    local strikes="$1"
    json_init "$RECOVER_STATE_JSON"
    json_set "$RECOVER_STATE_JSON" "timestamp" "$(date -Iseconds)"
    json_set "$RECOVER_STATE_JSON" "node_role" "$NODE_ROLE"
    json_set "$RECOVER_STATE_JSON" "Recovery_strikes" "$strikes"
    json_finalize "$RECOVER_STATE_JSON"
    /opt/semperfix/scripts/json-perms.sh "$RECOVER_STATE_JSON"
}

clear_recover_state() {
    json_init "$RECOVER_STATE_JSON"
    json_set "$RECOVER_STATE_JSON" "Recovery_strikes" "0"
    json_finalize "$RECOVER_STATE_JSON"
    /opt/semperfix/scripts/json-perms.sh "$RECOVER_STATE_JSON"
}

trigger_recovery() {
    log "Recovery triggered — calling Phoenix Role Switcher"
    /opt/semperfix/scripts/phoenix-role-switch.sh MASTERZERO-ACTIVE
}

# ---------------------------------------------------------
# Main
# ---------------------------------------------------------

main() {
    # Only run on passive SECONDARY
    [[ "$NODE_ROLE" != "MASTERZERO-RECOVER" ]] && exit 0

    local recovery_flag quic_unstable mesh_unstable strikes

    recovery_flag=$RECOVERY_STATUS
    quic_unstable=$(is_quic_unreachable)
    mesh_unstable=$(is_mesh_unstable_local)
    strikes=$(load_recover_state)

    log "Recovery check: recovery=$recovery_flag quic_unstable=$quic_unstable mesh_unstable=$mesh_unstable strikes=$strikes"

    # Policy:
    # - Supervisor signals signals recovery_needed=true
    # - QUIC reachable from SECONDARY
    # - local mesh stable
    if [[ "$recovery_flag" == "true" && "$quic_unstable" == "false" && "$mesh_unstable" == "false" ]]; then
        strikes=$((strikes + 1))
        log "Recovery strike recorded (count=$strikes)"
    else
        strikes=0
    fi

    save_recover_state "$strikes"

    # Require 2 consecutive strikes
    if (( strikes >= 2 )); then
        trigger_recovery
        log "Recovery Trigger"
        clear_recover_state
        log "Strike count cleared"
    else
        log "Recovery not yet triggered (strikes<2)"
    fi
}

main "$@"
