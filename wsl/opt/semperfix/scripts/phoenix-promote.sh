#!/usr/bin/env bash

# =====================================================================
# Phoenix Automation Suite — Promote
# Version: Phoenix v2.1
# Component: phoenix-promote
# Role: Controller / Responder / Observer (role-aware)
# Refactor: 2026-10-21 — v2.0 → v2.1 role model upgrade
# Maintainer: SemperFix Automation (Bruce)
# =====================================================================

#!/usr/bin/env bash

# =====================================================================
# Phoenix Automation Suite — Promote
# Version: Phoenix v2.2
# Component: phoenix-promote
# Role: SECONDARY-PASSIVE only
# =====================================================================

set -euo pipefail

umask 002

export LC_ALL=C.UTF-8
export LANG=C.UTF-8

# shellcheck disable=SC1091
source /opt/semperfix/scripts/phoenix-core.sh
# shellcheck disable=SC1091
source /opt/semperfix/scripts/phoenix-json.sh

phoenix_init

STATUS_JSON="${STATE_DIR}/phoenix-status.json"
PROMOTE_STATE_JSON="${STATE_DIR}/phoenix-promote.json"

LOGFILE="${LOG_DIR}/phoenix-promote.log"

# shellcheck disable=SC2034
PHOENIX_LOGFILE="$LOGFILE"

log() {
    phoenix_log_file "INFO" "$*"
}

# ---------------------------------------------------------
# Validation
# ---------------------------------------------------------

required_file() {

    local file="$1"

    [[ -f "$file" ]]
}

is_stale() {

    local file="$1"
    local max_age="$2"

    local now
    local modified

    now=$(date +%s)
    modified=$(stat -c %Y "$file")

    (( now - modified > max_age ))
}

validate_inputs() {

    required_file "$STATUS_JSON" || {
        log "Missing status file"
        return 1
    }

    jq . "$STATUS_JSON" >/dev/null 2>&1 || {
        log "Invalid status JSON"
        return 1
    }

    if is_stale "$STATUS_JSON" 300; then
        log "Status file stale"
        return 1
    fi

    return 0
}

# ---------------------------------------------------------
# Canonical State Accessors
# ---------------------------------------------------------

get_role() {
    jq -r '.node.role // "unknown"' "$STATUS_JSON"
}

get_failover_state() {
    jq -r '.failover.state // "unknown"' "$STATUS_JSON"
}

get_mesh_ok() {
    jq -r '.mesh.mesh_ok // "false"' "$STATUS_JSON"
}

get_quic_reachable() {
    jq -r '.quic.reachable // "false"' "$STATUS_JSON"
}

# ---------------------------------------------------------
# Strike State
# ---------------------------------------------------------

load_promote_state() {

    if [[ -f "$PROMOTE_STATE_JSON" ]]; then

        jq -r '.failover_strikes // 0' \
            "$PROMOTE_STATE_JSON" 2>/dev/null || echo 0

    else

        echo 0

    fi
}

save_promote_state() {

    local strikes="$1"

    # shellcheck disable=SC2034
    json_init "$PROMOTE_STATE_JSON"

    json_set "$PROMOTE_STATE_JSON" "timestamp" "$(date -Iseconds)"

    json_set "$PROMOTE_STATE_JSON" "node_role" "$NODE_ROLE"

    json_set "$PROMOTE_STATE_JSON" "failover_strikes" "$strikes"

    json_finalize "$PROMOTE_STATE_JSON"

    /opt/semperfix/scripts/json-perms.sh "$PROMOTE_STATE_JSON"
}

# ---------------------------------------------------------
# Promotion
# ---------------------------------------------------------

trigger_promotion() {

    log "Promotion triggered"

    ${ROLE_SWITCH_SCRIPT} "SECONDARY-ACTIVE"
}

# ---------------------------------------------------------
# Main
# ---------------------------------------------------------

main() {

    [[ "$NODE_ROLE" != "SECONDARY-PASSIVE" &&
       "$NODE_ROLE" != "SECONDARY" ]] && exit 0

    validate_inputs || {
        log "Promotion aborted due to invalid state"
        exit 1
    }

    local failover_state
    local mesh_ok
    local quic_ok
    local strikes

    failover_state=$(get_failover_state)
    mesh_ok=$(get_mesh_ok)
    quic_ok=$(get_quic_reachable)

    strikes=$(load_promote_state)

    log "Promotion check: failover=${failover_state} mesh_ok=${mesh_ok} quic_ok=${quic_ok} strikes=${strikes}"

    #
    # Promotion policy
    #
    # failover must be needed
    # mesh must be unhealthy
    # peer must be unreachable
    #

    if [[ "$failover_state" == "needed" &&
          "$mesh_ok" != "true" &&
          "$quic_ok" != "true"
    ]]
    then

        strikes=$((strikes + 1))

        log "Failover strike recorded count=${strikes}"

    else

        strikes=0

    fi

    save_promote_state "$strikes"

    #
    # Require two consecutive strikes
    #

    if (( strikes >= 2 )); then

        trigger_promotion

    else

        log "Promotion not triggered strikes=${strikes}"

    fi
}

main "$@"