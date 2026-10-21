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

set_role() {
    local new_role="$1"
    jq ".node.role = \"$new_role\"" "$CONFIG_FILE" \
        > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
}

snapshot_logs() {
    log "Phoenix v2 Descalate — log snapshot"

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

demote_secondary() {
    log "Descalate: SECONDARY-ACTIVE → SECONDARY-PASSIVE"

    # Flip role
    set_role "SECONDARY-PASSIVE"

    # Stop controller stack
    systemctl stop semperfix-phoenix-supervisor.timer || true
    systemctl stop semperfix-phoenix-heartbeat.timer || true
    systemctl stop semperfix-mesh-status.timer || true
    systemctl stop semperfix-quic-client.timer || true
    systemctl stop semperfix-phoenix-failover.timer || true
    systemctl stop semperfix-phoenix-descalate.timer || true
    systemctl stop semperfix-mesh-listener.service || true

    # Disable controller stack
    systemctl disable semperfix-phoenix-supervisor.timer || true
    systemctl disable semperfix-phoenix-heartbeat.timer || true
    systemctl disable semperfix-mesh-status.timer || true
    systemctl disable semperfix-quic-client.timer || true
    systemctl disable semperfix-phoenix-failover.timer || true
    systemctl disable semperfix-phoenix-descalate.timer || true
    systemctl disable semperfix-mesh-listener.service || true

    # Re-enable responder stack
    systemctl enable semperfix-quic-responder.service || true
    systemctl start semperfix-quic-responder.service || true

    log "SECONDARY demoted to passive mode"
}

recover_masterzero() {
    log "Descalate: MASTERZERO-DEGRADED → MASTERZERO-RECOVER"

    set_role "MASTERZERO-RECOVER"

    # MASTERZERO recovery logic could be expanded here
    log "MASTERZERO entering recovery mode"
}

main() {
    ROLE="$(get_role)"
    log "Descalate invoked for role: $ROLE"

    case "$ROLE" in
        SECONDARY-ACTIVE)
            snapshot_logs
            demote_secondary
            ;;
        MASTERZERO-DEGRADED)
            snapshot_logs
            recover_masterzero
            ;;
        MASTERZERO-ACTIVE)
            snapshot_logs
            log "MASTERZERO-ACTIVE: snapshot only"
            ;;
        *)
            log "Descalate disabled for role: $ROLE"
            ;;
    esac
}

main "$@"
