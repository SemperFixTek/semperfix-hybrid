#!/usr/bin/env bash
set -euo pipefail

umask 002
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

dos2unix "$0" 2>/dev/null || true

source /opt/semperfix/scripts/phoenix-core.sh
phoenix_init

HB_LOG="${LOG_DIR}/phoenix-heartbeat.log"
SUP_LOG="${LOG_DIR}/phoenix-supervisor.log"
DESC_LOG="${LOG_DIR}/phoenix-descalate.log"

PHOENIX_LOGFILE="$DESC_LOG"
log() { phoenix_log_file "INFO" "$*"; }

STATUS_FILE="${STATE_DIR}/phoenix-status.json"
CONFIG_FILE="/opt/semperfix/config/phoenix.json"

get_role() {
    jq -r '.node.role // "UNKNOWN"' "$CONFIG_FILE" 2>/dev/null || echo "UNKNOWN"
}

snapshot_logs() {
    log "Phoenix v2.1 Descalate — log snapshot"

    if [[ -f "$HB_LOG" ]]; then
        log "Heartbeat log (last 20 lines):"
        tail -n 20 "$HB_LOG" >> "$DESC_LOG"
    else
        log "No heartbeat log found"
    fi

    if [[ -f "$SUP_LOG" ]]; then
        log "Supervisor log (last 20 lines):"
        tail -n 20 "$SUP_LOG" >> "$DESC_LOG"
    else
        log "No supervisor log found"
    fi

    chown root:semperfix "$DESC_LOG"
    chmod 664 "$DESC_LOG"
}

main() {
    ROLE="$(get_role)"
    log "Descalate invoked for role: $ROLE"

    case "$ROLE" in
        SECONDARY-ACTIVE)
            snapshot_logs
            log "Descalate: SECONDARY-ACTIVE → SECONDARY-PASSIVE via role-switcher"
            /opt/semperfix/scripts/phoenix-role-switch.sh SECONDARY-PASSIVE
            ;;

        MASTERZERO-DEGRADED)
            snapshot_logs
            log "Descalate: MASTERZERO-DEGRADED → MASTERZERO-RECOVER via role-switcher"
            /opt/semperfix/scripts/phoenix-role-switch.sh MASTERZERO-RECOVER
            ;;

        MASTERZERO-ACTIVE)
            snapshot_logs
            log "MASTERZERO-ACTIVE: snapshot only, no descalation"
            ;;

        *)
            log "Descalate disabled for role: $ROLE"
            ;;
    esac
}

main "$@"
