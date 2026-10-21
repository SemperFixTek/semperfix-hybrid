#!/usr/bin/env bash
set -euo pipefail

umask 002
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

ROLE_FILE="/opt/semperfix/config/phoenix.json"
STATE_DIR="/opt/semperfix/state"
PRESET_DIR="/etc/systemd/system-preset"
LOG_DIR="/opt/semperfix/logs"

log() {
    echo "[ROLE-SWITCH] $*" | tee -a "${LOG_DIR}/role-switch.log"
}

usage() {
    echo "Usage: $0 <MASTERZERO-ACTIVE|MASTERZERO-DEGRADED|MASTERZERO-RECOVER|SECONDARY-ACTIVE|SECONDARY-PASSIVE|OFFSITE>"
    exit 1
}

NEW_ROLE="${1:-}"
[[ -z "$NEW_ROLE" ]] && usage

case "$NEW_ROLE" in
    MASTERZERO-ACTIVE|MASTERZERO-DEGRADED|MASTERZERO-RECOVER|\
    SECONDARY-ACTIVE|SECONDARY-PASSIVE|OFFSITE)
        ;;
    *)
        log "Invalid role: $NEW_ROLE"
        usage
        ;;
esac

log "Switching Phoenix node role to: $NEW_ROLE"

# ------------------------------------------------------------
# 1. Update phoenix.json
# ------------------------------------------------------------
log "Updating phoenix.json"
jq --arg role "$NEW_ROLE" '.role = $role' "$ROLE_FILE" > "${ROLE_FILE}.tmp"
mv "${ROLE_FILE}.tmp" "$ROLE_FILE"

# ------------------------------------------------------------
# 2. Apply correct preset
# ------------------------------------------------------------
PRESET_FILE="${PRESET_DIR}/90-semperfix-${NEW_ROLE,,}.preset"

if [[ ! -f "$PRESET_FILE" ]]; then
    log "ERROR: Preset file not found: $PRESET_FILE"
    exit 1
fi

log "Applying preset: $PRESET_FILE"
systemctl preset-all
systemctl daemon-reload

# ------------------------------------------------------------
# 3. STOP units that should NOT run under this role
# ------------------------------------------------------------
stop_units() {
    for unit in "$@"; do
        log "Stopping: $unit"
        systemctl stop "$unit" 2>/dev/null || true
        systemctl disable "$unit" 2>/dev/null || true
    done
}

start_units() {
    for unit in "$@"; do
        log "Starting: $unit"
        systemctl enable "$unit" 2>/dev/null || true
        systemctl restart "$unit" 2>/dev/null || true
    done
}

# ------------------------------------------------------------
# 4. Telemetry Vacuum — remove stale JSON
# ------------------------------------------------------------
vacuum_telemetry() {
    log "Vacuuming stale telemetry for role: $NEW_ROLE"

    # Controller-only telemetry
    rm -f "${STATE_DIR}/phoenix-supervisor.json"
    rm -f "${STATE_DIR}/phoenix-failover.json"
    rm -f "${STATE_DIR}/mesh-listener.json"
    rm -f "${STATE_DIR}/quic-client-status.json"

    # Passive-only telemetry
    rm -f "${STATE_DIR}/quic-responder-status.json"

    # OFFSITE-only telemetry
    rm -f "${STATE_DIR}/offsite-heartbeat.json"

    # Old mesh handshake artifacts
    rm -f "${STATE_DIR}/mesh-handshake.json"

    # Old export artifacts
    rm -f "${STATE_DIR}/windows-heartbeat.json"

    log "Telemetry vacuum complete"
}

vacuum_telemetry

# ------------------------------------------------------------
# 5. Role-specific unit control
# ------------------------------------------------------------
case "$NEW_ROLE" in

    MASTERZERO-ACTIVE)
        stop_units \
            semperfix-quic-responder.service \
            semperfix-phoenix-promote.timer

        start_units \
            semperfix-phoenix-supervisor.timer \
            semperfix-phoenix-failover.timer \
            semperfix-phoenix-descalate.timer \
            semperfix-quic-client.timer \
            semperfix-mesh-listener.service \
            semperfix-phoenix-heartbeat.timer \
            semperfix-mesh-status.timer \
            semperfix-state-export-windows.timer
        ;;

    MASTERZERO-DEGRADED)
        stop_units semperfix-phoenix-descalate.timer

        start_units \
            semperfix-phoenix-supervisor.timer \
            semperfix-phoenix-failover.timer \
            semperfix-quic-client.timer \
            semperfix-mesh-listener.service \
            semperfix-phoenix-heartbeat.timer \
            semperfix-mesh-status.timer \
            semperfix-state-export-windows.timer
        ;;

    MASTERZERO-RECOVER)
        stop_units semperfix-phoenix-failover.timer

        start_units \
            semperfix-phoenix-descalate.timer \
            semperfix-phoenix-supervisor.timer \
            semperfix-quic-client.timer \
            semperfix-mesh-listener.service \
            semperfix-phoenix-heartbeat.timer \
            semperfix-mesh-status.timer \
            semperfix-state-export-windows.timer
        ;;

    SECONDARY-ACTIVE)
        stop_units \
            semperfix-quic-responder.service \
            semperfix-phoenix-promote.timer

        start_units \
            semperfix-phoenix-supervisor.timer \
            semperfix-phoenix-failover.timer \
            semperfix-phoenix-descalate.timer \
            semperfix-quic-client.timer \
            semperfix-mesh-listener.service \
            semperfix-phoenix-heartbeat.timer \
            semperfix-mesh-status.timer \
            semperfix-state-export-windows.timer
        ;;

    SECONDARY-PASSIVE)
        stop_units \
            semperfix-phoenix-supervisor.service \
            semperfix-phoenix-supervisor.timer \
            semperfix-phoenix-failover.service \
            semperfix-phoenix-failover.timer \
            semperfix-phoenix-descalate.service \
            semperfix-phoenix-descalate.timer \
            semperfix-quic-client.service \
            semperfix-quic-client.timer \
            semperfix-mesh-listener.service

        start_units \
            semperfix-quic-responder.service \
            semperfix-phoenix-promote.timer \
            semperfix-phoenix-heartbeat.timer \
            semperfix-mesh-status.timer \
            semperfix-state-export-windows.timer
        ;;

    OFFSITE)
        stop_units \
            semperfix-quic-responder.service \
            semperfix-quic-client.timer \
            semperfix-phoenix-supervisor.timer \
            semperfix-phoenix-failover.timer \
            semperfix-phoenix-descalate.timer \
            semperfix-phoenix-promote.timer \
            semperfix-mesh-listener.service

        start_units \
            semperfix-phoenix-heartbeat.timer \
            semperfix-mesh-status.timer \
            semperfix-state-export-windows.timer
        ;;
esac

log "Phoenix role switch complete: $NEW_ROLE"
exit 0
