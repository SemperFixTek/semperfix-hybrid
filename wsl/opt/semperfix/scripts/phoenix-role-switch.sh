#!/usr/bin/env bash

# =====================================================================
# Phoenix Automation Suite — Role Switch
# Version: Phoenix v2.1
# Component: phoenix-role-switch
# Role: Controller / Responder / Observer (role-aware)
# Refactor: 2026-10-21 — v2.0 → v2.1 role model upgrade
# Maintainer: SemperFix Automation (Bruce)
# =====================================================================

set -euo pipefail

umask 002
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

ROLE_FILE="/opt/semperfix/config/phoenix.json"
STATE_DIR="/var/lib/semperfix/state"
TRANS_DIR="$STATE_DIR/secondary"
LOG_DIR="/opt/semperfix/logs"

# Ensure required directories exist
mkdir -p "$(dirname "$ROLE_FILE")"
mkdir -p "$STATE_DIR"
mkdir -p "$TRANS_DIR"
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
jq --arg role "${NEW_ROLE}" '.node.role = $role' "${ROLE_FILE}" > "${ROLE_FILE}.tmp"
mv "${ROLE_FILE}.tmp" "${ROLE_FILE}"

# ------------------------------------------------------------
# 2. Telemetry Vacuum — remove stale JSON
# ------------------------------------------------------------
vacuum_telemetry() {
    
    log "Vacuuming stale telemetry for role: $NEW_ROLE"

    rm -f "${TRANS_DIR}/phoenix-supervisor.json"
    rm -f "${TRANS_DIR}/phoenix-failover.json"
    rm -f "${TRANS_DIR}/mesh-listener.json"
    rm -f "${TRANS_DIR}/quic-client-status.json"
    rm -f "${TRANS_DIR}/quic-responder-status.json"
    rm -f "${TRANS_DIR}/offsite-heartbeat.json"
    rm -f "${TRANS_DIR}/mesh-handshake.json"
    rm -f "${TRANS_DIR}/windows-heartbeat.json"

    log "Telemetry vacuum complete"
}

 vacuum_telemetry

# ------------------------------------------------------------
# 3. Unit control helpers
# ------------------------------------------------------------
stop_units() {
    for unit in "$@"; do
        log "Disabling/stopping: $unit"
        systemctl disable --now "$unit" 2>/dev/null || true
        sleep .8
    
    done
}

start_units() {
        sleep 5
    for unit in "$@"; do
        log "Enabling/starting: $unit"
        systemctl enable --now "$unit" 2>/dev/null || true
        sleep .8
   
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
            semperfix-phoenix-recovery.timer \
            semperfix-state-export-windows.timer \
            semperfix-phoenix-descalate.timer 

        start_units \
            semperfix-phoenix-failover.timer \
            semperfix-network-normalizer.service \
            semperfix-inotify-monitor.service \
            semperfix-mesh-listener.service \
            semperfix-supervisor.timer \
            semperfix-quic-client.timer \
            semperfix-phoenix-heartbeat.timer \
            semperfix-mesh-status.timer \
            semperfix-mirror-secondary.timer \
            semperfix-phoenix-status-write.timer
        ;;

    MASTERZERO-DEGRADED)
        stop_units \
            semperfix-phoenix-failover.timer \
            semperfix-quic-responder.service \
            semperfix-phoenix-promote.timer \
            semperfix-phoenix-recovery.timer \
            semperfix-state-export-windows.timer \
            

        start_units \
            semperfix-phoenix-descalate.timer \
            semperfix-network-normalizer.service \
            semperfix-inotify-monitor.service \
            semperfix-mesh-listener.service \
            semperfix-supervisor.timer \
            semperfix-quic-client.timer \
            semperfix-phoenix-heartbeat.timer \
            semperfix-mesh-status.timer \
            semperfix-mirror-secondary.timer \
            semperfix-phoenix-status-write.timer
        ;;

    MASTERZERO-RECOVER)
        stop_units \
            semperfix-phoenix-failover.timer \
            semperfix-phoenix-descalate.timer \
            semperfix-quic-responder.service \
            semperfix-phoenix-promote.timer \
            semperfix-state-export-windows.timer \
            

        start_units \
            semperfix-phoenix-recovery.timer \
            semperfix-network-normalizer.service \
            semperfix-inotify-monitor.service \
            semperfix-mesh-listener.service \
            semperfix-supervisor.timer \
            semperfix-quic-client.timer \
            semperfix-phoenix-heartbeat.timer \
            semperfix-mesh-status.timer \
            semperfix-mirror-secondary.timer \
            semperfix-phoenix-status-write.timer
        ;;

    SECONDARY-ACTIVE)
        stop_units \
            semperfix-phoenix-failover.timer \
            semperfix-quic-responder.service \
            semperfix-phoenix-promote.timer \
            semperfix-phoenix-recovery.timer \
            semperfix-mirror-secondary.timer 

        start_units \
            semperfix-phoenix-descalate.timer \
            semperfix-network-normalizer.service \
            semperfix-inotify-monitor.service \
            semperfix-mesh-listener.service \
            semperfix-supervisor.timer \
            semperfix-quic-client.timer \
            semperfix-phoenix-heartbeat.timer \
            semperfix-mesh-status.timer \
            semperfix-state-export-windows.timer \
            semperfix-phoenix-status-write.timer
        ;;

    SECONDARY-PASSIVE)
        stop_units \
            semperfix-phoenix-failover.timer \
            semperfix-phoenix-recovery.timer \
            semperfix-phoenix-descalate.timer \
            semperfix-supervisor.timer \
            semperfix-quic-client.timer \
            semperfix-mesh-listener.service \
            semperfix-mirror-secondary.timer 

        start_units \
            semperfix-phoenix-promote.timer \
            semperfix-network-normalizer.service \
            semperfix-inotify-monitor.service \
            semperfix-quic-responder.service \
            semperfix-phoenix-heartbeat.timer \
            semperfix-mesh-status.timer \
            semperfix-state-export-windows.timer \
            semperfix-phoenix-status-write.timer
        ;;

    OFFSITE)
        stop_units \
            semperfix-phoenix-failover.timer \
            semperfix-phoenix-recovery.timer \
            semperfix-phoenix-recovery.service \
            semperfix-phoenix-descalate.timer \
            semperfix-phoenix-promote.timer \
            semperfix-quic-responder.service \
            semperfix-quic-client.timer \
            semperfix-supervisor.timer \
            semperfix-mesh-listener.service \
            semperfix-mirror-secondary.service

        start_units \
            semperfix-network-normalizer.service \
            semperfix-inotify-monitor.service \
            semperfix-phoenix-heartbeat.timer \
            semperfix-mesh-status.timer \
            semperfix-state-export-windows.timer
        ;;

esac
#log "Reloading systemd daemon"
#systemctl daemon-reload

log "Phoenix role switch complete: $NEW_ROLE"
exit 0
