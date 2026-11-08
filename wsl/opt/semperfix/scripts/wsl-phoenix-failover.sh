#!/usr/bin/env bash
# =====================================================================
# Phoenix Automation Suite — Failover
# Version: Phoenix v2.1
# Component: phoenix-failover
# Role: Controller / Responder / Observer (role-aware)
# Refactor: 2026-10-21 — v2.0 → v2.1 role model upgrade
# Maintainer: SemperFix Automation (Bruce)
# =====================================================================

set -euo pipefail

umask 002
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

dos2unix "$0" 2>/dev/null || true

source /opt/semperfix/scripts/phoenix-core.sh
source /opt/semperfix/scripts/phoenix-json.sh
phoenix_init

FAILOVER_JSON="${STATE_DIR}/phoenix-failover.json"
LOGFILE="${LOG_DIR}/phoenix-failover.log"
PHOENIX_LOGFILE="$LOGFILE"

log() { phoenix_log_file "INFO" "$*"; }

# ---------------------------------------------------------
# Health checks
# ---------------------------------------------------------


log "Checking heartbeat"
is_heartbeat_stale() {
    local ts
    ts=$(jq -r '."timestamp"' "${STATE_DIR}/phoenix-heartbeat.json" 2>/dev/null || echo "")
    [[ -z "$ts" ]] && echo "true" && return

    local now epoch_ts
    now=$(date +%s)
    epoch_ts=$(date -d "$ts" +%s 2>/dev/null || echo 0)

    (( now - epoch_ts > 60 )) && echo "true" || echo "false" 
}
log "checking mesh"
is_mesh_degraded() {
    jq -r '
      (.handshake_status != "pass")
      or (.verify_status != "pass")
      or (.activate_status != "pass")
    ' "${STATE_DIR}/phoenix-supervisor.json" 2>/dev/null || echo "true"
}
log "checking quic"
is_quic_unreachable() {
    local value

    if ! value=$(jq -r '.quic_reachable' \
        "${STATE_DIR}/quic-client-status.json" 2>/dev/null)
    then
        log "QUIC status file unreadable"
        echo "unknown"
        return
    fi

#    log "QUIC reachable=$value"

   [[ "$value" == "false" ]] && echo "true" || echo "false"
}
log "Checking Syncthing"
is_syncthing_unreachable() {
    local code
    code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 3 \
        -m 5 -H "X-API-Key: $API_KEY" "$API_URL/system/ping" 2>/dev/null || echo "000")


    [[ "$code" == "200" ]] && echo "false" || echo "true"
}

load_failover_state() {
    if [[ -f "$FAILOVER_JSON" ]]; then
        jq -r '.failover_strikes // 0' "$FAILOVER_JSON" 2>/dev/null
    else
        echo 0
    fi
}

trigger_failover() {
    log "triggering failover"
    /opt/semperfix/scripts/phoenix-role-switch.sh "MASTERZERO-DEGRADED"
}
save_failover_state() {
    local strikes="$1"
    json_init "$FAILOVER_JSON"
    json_set "$FAILOVER_JSON" "timestamp" "$(date -Iseconds)"
    json_set "$FAILOVER_JSON" "node_role" "$NODE_ROLE"
    json_set "$FAILOVER_JSON" "failover_needed" "$failover_needed"
    json_set "$FAILOVER_JSON" "reason" "$reason"
    json_set "$FAILOVER_JSON" "failover_strikes" "$strikes"
    json_finalize "$FAILOVER_JSON"
    /opt/semperfix/scripts/json-perms.sh "$FAILOVER_JSON"
}

clear_failover_state() {
    json_init "$FAILOVER_JSON"
    json_set "$FAILOVER_JSON" "timestamp" "$(date -Iseconds)"
    json_set "$FAILOVER_JSON" "node_role" "$NODE_ROLE"
    json_set "$FAILOVER_JSON" "failover_needed" "$failover_needed"
    json_set "$FAILOVER_JSON" "reason" "$reason"
    json_set "$FAILOVER_JSON" "failover_strikes" "0"
    json_finalize "$FAILOVER_JSON"
    /opt/semperfix/scripts/json-perms.sh "$FAILOVER_JSON"
    
    log "Strike count cleared: $(load_failover_state)"
}

# ---------------------------------------------------------
# Main evaluator
# ---------------------------------------------------------
log "starting role-aware evaluation"
main() {

    # Only MASTERZERO evaluates failover
    case "$NODE_ROLE" in
        MASTERZERO-ACTIVE|MASTERZERO-DEGRADED|MASTERZERO-RECOVER)
            log "MASTERZERO node, will evaluate failover"
            ;;
        *)
            log "not MASTERZERO node, failover bypassed"
            exit 0
            ;;
    esac
    
    local heartbeat_stale mesh_bad quic_bad syncthing_bad strikes
    local failover_needed="false"
    local reason="none"

    phoenix_debug "assign variables"
    
   
    heartbeat_stale=$(is_heartbeat_stale)
    mesh_bad=$(is_mesh_degraded)
    quic_bad=$(is_quic_unreachable)
    syncthing_bad=$(is_syncthing_unreachable)
    
    log "heartbeat_stale=$heartbeat_stale"
    log "mesh_bad=$mesh_bad"
    log "quic_bad=$quic_bad"
    log "syncthing_bad=$syncthing_bad"
    log "node_role=${NODE_ROLE}"
    
    
    if [[ "$heartbeat_stale" == "true" ]] then
        failover_needed="true"
        reason="heartbeat stale"
    elif [[ "${mesh_bad}" == "true" ]]; then
        failover_needed="true"
        reason="mesh degraded"
    elif [[ "$syncthing_bad" == "true" ]]; then
        failover_needed="true"
        reason="syncthing_unreachable"
    elif [[ "$quic_bad" == "true" ]]; then
        failover_needed="true"
        reason="quic_unreachable"
    elif [[ "$quic_bad" == "unknown" ]]; then
        log "Skipping failover decision because QUIC state is unknown"
    fi

    #> Write failover telemetry
    #json_init "$FAILOVER_JSON"
    #json_set "$FAILOVER_JSON" "timestamp" "$(date -Iseconds)"
    #json_set "$FAILOVER_JSON" "node_role" "$NODE_ROLE"
    #json_set "$FAILOVER_JSON" "failover_needed" "$failover_needed"
    #json_set "$FAILOVER_JSON" "reason" "$reason"
    #json_finalize "$FAILOVER_JSON"

    #/opt/semperfix/scripts/json-perms.sh "$FAILOVER_JSON"

   # Policy:
    # - Supervisor signals signals failover_needed=true
    # - QUIC reachable from MASTERZERO
    # - local mesh stable
    strikes=$(load_failover_state)
    if [[ "$heartbeat_stale" == "true" || "$quic_bad" == "true" || \
          "$mesh_bad" == "true" || "$syncthing_bad" == "true" ]]; then
        strikes=$((strikes + 1))
        log "Failover strike recorded (count=$strikes)"
    else
        strikes=0
    fi

    log "Failover evaluation complete: failover_needed=$failover_needed reason=$reason"

    save_failover_state "$strikes"

    # Require 2 consecutive strikes
    if (( strikes >= 2 )); then       
        clear_failover_state
        trigger_failover      
    else
        log "Failover not yet triggered (strikes<2)"
    fi
}
main "$@"
