#!/usr/bin/env bash

# =====================================================================
# Phoenix Automation Suite — Recover
# Version: Phoenix v2.1.1
# Component: phoenix-recover
# Role: Controller / Responder / Observer (role-aware)
# Refactor: 2026-11-09 — v2.1 → v2.1.1 role model upgrade
# Maintainer: SemperFix Automation (Bruce)
# Audit Refactor: 2026-11-09
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

RECOVER_JSON="${STATE_DIR}/phoenix-recover.json"
STATUS_JSON="${STATE_DIR}/phoenix-status.json"

LOGFILE="${LOG_DIR}/phoenix-recover.log"
LOCKFILE="/run/lock/phoenix-recover.lock"

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
    log "Recover already running"
    exit 0
}

# ---------------------------------------------------------
# Helpers
# ---------------------------------------------------------

safe_status_field() {

    local expression="$1"

    jq -r "${expression} // \"unknown\"" \
        "$STATUS_JSON" 2>/dev/null || echo "unknown"
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
# Recovery Health Checks
# ---------------------------------------------------------

recovery_ready() {

    local mesh_ok
    local api_ok
    local peer_connected
    local syncthing_ready
    local quic_ok
    local failover_state

    mesh_ok=$(safe_status_field '.mesh.mesh_ok')
    api_ok=$(safe_status_field '.heartbeat.api_ok')
    peer_connected=$(safe_status_field '.heartbeat.peer_connected')
    syncthing_ready=$(safe_status_field '.heartbeat.syncthing_ready')
    quic_ok=$(safe_status_field '.heartbeat.quic_ok')
    failover_state=$(safe_status_field '.failover.state')

    [[ "$mesh_ok" == "true" &&
       "$api_ok" == "true" &&
       "$peer_connected" == "true" &&
       "$syncthing_ready" == "true" &&
       "$quic_ok" == "true" &&
       "$failover_state" == "not_needed"
    ]]
}

# ---------------------------------------------------------
# Strike Tracking
# ---------------------------------------------------------

load_recovery_state() {

    if [[ -f "$RECOVER_JSON" ]]; then

        jq -r '.recovery_strikes // 0' "$RECOVER_JSON" 2>/dev/null || echo 0

    else

        echo 0

    fi
}

save_recovery_state() {

    local strikes="$1"

    json_init "$RECOVER_JSON"

    json_set "$RECOVER_JSON" "timestamp" "$(date -Iseconds)"
    json_set "$RECOVER_JSON" "node_role" "$NODE_ROLE"
    json_set "$RECOVER_JSON" "recovery_ready" "$RECOVERY_READY"
    json_set "$RECOVER_JSON" "reason" "$RECOVERY_REASON"
    json_set "$RECOVER_JSON" "recovery_strikes" "$strikes"

    json_finalize "$RECOVER_JSON"

    /opt/semperfix/scripts/json-perms.sh "$RECOVER_JSON"
}

clear_recovery_state() {

    json_init "$RECOVER_JSON"

    json_set "$RECOVER_JSON" "timestamp" "$(date -Iseconds)"
    json_set "$RECOVER_JSON" "node_role" "$NODE_ROLE"
    json_set "$RECOVER_JSON" "recovery_ready" "false"
    json_set "$RECOVER_JSON" "reason" "none"
    json_set "$RECOVER_JSON" "recovery_strikes" "0"

    json_finalize "$RECOVER_JSON"

    /opt/semperfix/scripts/json-perms.sh "$RECOVER_JSON"
}

# ---------------------------------------------------------
# Recovery Action
# ---------------------------------------------------------

trigger_recovery() {

    log "Recovery triggered"

    "$ROLE_SWITCH_SCRIPT" MASTERZERO-ACTIVE
}

# ---------------------------------------------------------
# Main
# ---------------------------------------------------------

main() {

    [[ "$NODE_ROLE" == "MASTERZERO-RECOVER" ]] || {

        log "Recovery disabled for role=${NODE_ROLE}"
        exit 0
    }

    local stale
    local strikes

    RECOVERY_READY="false"
    RECOVERY_REASON="none"

    stale=$(is_status_stale)

    if [[ "$stale" == "true" ]]; then

        RECOVERY_REASON="status_stale"

    elif recovery_ready; then

        RECOVERY_READY="true"
        RECOVERY_REASON="mesh_healthy"

    fi

    strikes=$(load_recovery_state)

    if [[ "$RECOVERY_READY" == "true" ]]; then

        strikes=$((strikes + 1))

        log "Recovery strike recorded (count=${strikes})"

    else

        strikes=0

    fi

    save_recovery_state "$strikes"

    log "recovery_ready=${RECOVERY_READY}"
    log "reason=${RECOVERY_REASON}"
    log "strikes=${strikes}"

    #
    # Require 2 consecutive healthy evaluations
    #

    if (( strikes >= 2 )); then

        clear_recovery_state

        trigger_recovery

    else

        log "Recovery not triggered (strikes < 2)"

    fi
}

main "$@"
