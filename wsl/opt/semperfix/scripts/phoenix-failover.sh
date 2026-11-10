#!/usr/bin/env bash

# =====================================================================
# Phoenix Automation Suite — Failover
# Version: Phoenix v2.1
# Component: phoenix-failover
# Role: Controller / Responder / Observer (role-aware)
# Refactor: 2026-11-09 — v2.1 → v2.1.1 role model upgrade
# Maintainer: SemperFix Automation (Bruce)
# Audit 2026-11-09
# =====================================================================

set -euo pipefail

umask 002
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

dos2unix "$0" >/dev/null 2>&1 || true

# shellcheck disable=SC1091
source /opt/semperfix/scripts/phoenix-core.sh
# shellcheck disable=SC1091
source /opt/semperfix/scripts/phoenix-json.sh

phoenix_init

FAILOVER_JSON="${STATE_DIR}/phoenix-failover.json"
STATUS_JSON="${STATE_DIR}/phoenix-status.json"

LOGFILE="${LOG_DIR}/phoenix-failover.log"
LOCKFILE="/run/lock/phoenix-failover.lock"

# shellcheck disable=SC2034
PHOENIX_LOGFILE="$LOGFILE"

log() {
    phoenix_log_file "INFO" "$*"
}

# ---------------------------------------------------------
# Locking
# ---------------------------------------------------------

exec 200>"$LOCKFILE"

flock -n 200 || {
    log "Failover already running"
    exit 0
}

# ---------------------------------------------------------
# Helpers
# ---------------------------------------------------------

safe_status_field() {

    local expression="$1"

    jq -r "${expression} // \"unknown\"" "$STATUS_JSON" 2>/dev/null || echo "unknown"
}

# ---------------------------------------------------------
# Status Freshness
# ---------------------------------------------------------

is_status_stale() {

    local ts

    ts=$(jq -r '.meta.timestamp // empty' "$STATUS_JSON" 2>/dev/null || true)

    [[ -z "$ts" ]] && {
        echo "true"
        return
    }

    local now
    local epoch_ts

    now=$(date +%s)
    epoch_ts=$(date -d "$ts" +%s 2>/dev/null || echo 0)

    (( now - epoch_ts > 90 )) &&
        echo "true" ||
        echo "false"
}

# ---------------------------------------------------------
# Aggregated Health Checks
# ---------------------------------------------------------

is_mesh_degraded() {

    local mesh_ok

    mesh_ok=$(
        safe_status_field '.mesh.mesh_ok'
    )

    [[ "$mesh_ok" == "true" ]] &&
        echo "false" ||
        echo "true"
}

is_quic_unreachable() {

    local value

    value=$(
        safe_status_field '.quic.reachable'
    )

    case "$value" in

        true)
            echo "false"
            ;;

        false)
            echo "true"
            ;;

        *)
            echo "unknown"
            ;;

    esac
}

is_syncthing_unreachable() {

    local value

    value=$(
        safe_status_field '.heartbeat.syncthing_ready'
    )

    [[ "$value" == "true" ]] &&
        echo "false" ||
        echo "true"
}

is_peer_disconnected() {

    local value

    value=$(
        safe_status_field '.heartbeat.peer_connected'
    )

    [[ "$value" == "true" ]] &&
        echo "false" ||
        echo "true"
}

# ---------------------------------------------------------
# Strike Tracking
# ---------------------------------------------------------

load_failover_state() {

    if [[ -f "$FAILOVER_JSON" ]]; then

        jq -r '.failover_strikes // 0' "$FAILOVER_JSON" 2>/dev/null || echo 0
    else
        echo 0
    fi
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
    json_set "$FAILOVER_JSON" "failover_needed" "false"
    json_set "$FAILOVER_JSON" "reason" "none"
    json_set "$FAILOVER_JSON" "failover_strikes" "0"

    json_finalize "$FAILOVER_JSON"

    /opt/semperfix/scripts/json-perms.sh "$FAILOVER_JSON"
}

trigger_failover() {

    log "Triggering failover"

    /opt/semperfix/scripts/phoenix-role-switch.sh \
        "MASTERZERO-DEGRADED"
}

# ---------------------------------------------------------
# Main
# ---------------------------------------------------------

main() {

    case "$NODE_ROLE" in

        MASTERZERO-ACTIVE)

            log "MASTERZERO-ACTIVE evaluating failover"
            ;;

        *)

            log "Failover disabled for role=${NODE_ROLE}"
            exit 0
            ;;

    esac

    local stale
    local mesh_bad
    local quic_bad
    local syncthing_bad
    local peer_bad
    local strikes

    failover_needed="false"
    reason="none"

    stale=$(is_status_stale)
    mesh_bad=$(is_mesh_degraded)
    quic_bad=$(is_quic_unreachable)
    syncthing_bad=$(is_syncthing_unreachable)
    peer_bad=$(is_peer_disconnected)

    log "status_stale=${stale}"
    log "mesh_bad=${mesh_bad}"
    log "quic_bad=${quic_bad}"
    log "syncthing_bad=${syncthing_bad}"
    log "peer_bad=${peer_bad}"

    if [[ "$stale" == "true" ]]; then

        failover_needed="true"
        reason="status_stale"

    elif [[ "$mesh_bad" == "true" ]]; then

        failover_needed="true"
        reason="mesh_degraded"

    elif [[ "$syncthing_bad" == "true" ]]; then

        failover_needed="true"
        reason="syncthing_unreachable"

    elif [[ "$peer_bad" == "true" ]]; then

        failover_needed="true"
        reason="peer_disconnected"

    elif [[ "$quic_bad" == "true" ]]; then

        failover_needed="true"
        reason="quic_unreachable"

    fi

    strikes=$(load_failover_state)

    if [[ "$failover_needed" == "true" ]]; then

        strikes=$((strikes + 1))

        log "Failover strike recorded (count=${strikes})"

    else

        strikes=0

    fi

    save_failover_state "$strikes"

    log "failover_needed=${failover_needed}"
    log "reason=${reason}"
    log "strikes=${strikes}"

    if (( strikes >= 2 )); then

        clear_failover_state

        trigger_failover

    else

        log "Failover not triggered (strikes < 2)"

    fi
}

main "$@"