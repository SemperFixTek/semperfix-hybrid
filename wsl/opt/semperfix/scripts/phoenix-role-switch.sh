#!/usr/bin/env bash
set -euo pipefail

umask 002
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

ROLE_FILE="/opt/semperfix/config/phoenix.json"
STATE_DIR="/var/lib/semperfix/state"
LOG_DIR="/opt/semperfix/logs"

# Ensure required directories exist
mkdir -p "$(dirname "$ROLE_FILE")"
mkdir -p "$STATE_DIR"
mkdir -p "$LOG_DIR"


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
jq --arg role "$NEW_ROLE" '.node.role = $role' "$ROLE_FILE" > "${ROLE_FILE}.tmp"
mv "${ROLE_FILE}.tmp" "$ROLE_FILE"

# ------------------------------------------------------------
# 2. Telemetry Vacuum — remove stale JSON
# ------------------------------------------------------------
vacuum_telemetry() {
    log "Vacuuming stale telemetry for role: $NEW_ROLE"

    rm -f "${STATE_DIR}/phoenix-supervisor.json"
    rm -f "${STATE_DIR}/phoenix-failover.json"
    rm -f "${STATE_DIR}/mesh-listener.json"
    rm -f "${STATE_DIR}/quic-client-status.json"
    rm -f "${STATE_DIR}/quic-responder-status.json"
    rm -f "${STATE_DIR}/offsite-heartbeat.json"
    rm -f "${STATE_DIR}/mesh-handshake.json"
    rm -f "${STATE_DIR}/windows-heartbeat.json"

    log "Telemetry vacuum complete"
}

vacuum_telemetry

# ------------------------------------------------------------
# 3. Unit control helpers
# ------------------------------------------------------------
stop_units() {
    for unit in "$@"; do
        log "Stopping: $unit"
        systemctl stop "$unit" 2>/dev/null || true
        log "Disabling: $unit"
        systemctl disable "$unit" 2>/dev/null || true
    done
}

start_units() {
    for unit in "$@"; do
        log "Enabling: $unit"
        systemctl enable "$unit" 2>/dev/null || true
        log "Starting: $unit"
        systemctl restart "$unit" 2>/dev/null || true
    done
}

# ------------------------------------------------------------
# 4. Role-specific unit control
# ------------------------------------------------------------
case "$NEW_ROLE" in

    MASTERZERO-ACTIVE)
        stop_units \
            semperfix-quic-responder.service \
            semperfix-phoenix-promote.timer \
            semperfix-state-export-windows.timer

        start_units \
            semperfix-network-normalizer.service \
            semperfix-phoenix-supervisor.timer \
            semperfix-phoenix-failover.timer \
            semperfix-phoenix-descalate.timer \
            semperfix-quic-client.timer \
            semperfix-mesh-listener.service \
            semperfix-phoenix-heartbeat.timer \
            semperfix-mesh-status.timer \
            semperfix-mirror-secondary.timer
        ;;

    MASTERZERO-DEGRADED)
        stop_units \
            semperfix-phoenix-descalate.timer \
            semperfix-state-export-windows.timer

        start_units \
            semperfix-network-normalizer.service \
            semperfix-phoenix-supervisor.timer \
            semperfix-phoenix-failover.timer \
            semperfix-quic-client.timer \
            semperfix-mesh-listener.service \
            semperfix-phoenix-heartbeat.timer \
            semperfix-mesh-status.timer \
            semperfix-mirror-secondary.timer
        ;;

    MASTERZERO-RECOVER)
        stop_units \
            semperfix-phoenix-failover.timer \
            semperfix-state-export-windows.timer

        start_units \
            semperfix-network-normalizer.service \
            semperfix-phoenix-descalate.timer \
            semperfix-phoenix-supervisor.timer \
            semperfix-quic-client.timer \
            semperfix-mesh-listener.service \
            semperfix-phoenix-heartbeat.timer \
            semperfix-mesh-status.timer \
            semperfix-mirror-secondary.timer
        ;;

    SECONDARY-ACTIVE)
        stop_units \
            semperfix-quic-responder.service \
            semperfix-phoenix-promote.timer \
            semperfix-state-export-windows.timer

        start_units \
            semperfix-network-normalizer.service \
            semperfix-phoenix-supervisor.timer \
            semperfix-phoenix-failover.timer \
            semperfix-phoenix-descalate.timer \
            semperfix-quic-client.timer \
            semperfix-mesh-listener.service \
            semperfix-phoenix-heartbeat.timer \
            semperfix-mesh-status.timer \
            semperfix-mirror-secondary.timer
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
            semperfix-mesh-listener.service \
            semperfix-mirror-secondary.timer

        start_units \
            semperfix-network-normalizer.service \
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
            semperfix-mesh-listener.service \
            

        start_units \
            semperfix-network-normalizer.service \
            semperfix-phoenix-heartbeat.timer \
            semperfix-mesh-status.timer \
            semperfix-state-export-windows.timer
        ;;
esac

log "Phoenix role switch complete: $NEW_ROLE"
exit 0
