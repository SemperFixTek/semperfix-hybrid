#!/usr/bin/env bash

# =====================================================================
# Phoenix Automation Suite — Role Switch
# Version: Phoenix v2.1
# Component: phoenix-role-switch
# Role: Controller / Responder / Observer (role-aware)
# Refactor: 2026-10-21 — v2.0 → v2.1 role model upgrade
# Maintainer: SemperFix Automation (Bruce)
# Audit 2026-11-04
# =====================================================================

set -euo pipefail

umask 002
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

ROLE_FILE="/opt/semperfix/config/phoenix.json"
STATE_DIR="/var/lib/semperfix/state"
TRANS_DIR="$STATE_DIR/secondary"
LOG_DIR="/opt/semperfix/logs"
LOCKFILE="/run/lock/phoenix-role-switch.lock"

# Ensure required directories exist
mkdir -p "$(dirname "$ROLE_FILE")"
mkdir -p "$STATE_DIR"
mkdir -p "$TRANS_DIR"
mkdir -p "$LOG_DIR"
mkdir -p "$(dirname "$LOCKFILE")"

# ------------------------------------------------------------
# Locking
# ------------------------------------------------------------

exec 200>"$LOCKFILE"

if ! flock -n 200; then
    echo "[WARN] Another role switch is already running"
    exit 1
fi

# Start of the script configuration and logging
log() {
    echo "[INFO] $*" | tee -a "${LOG_DIR}/role-switch.log"
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
log "Previous role: $(jq -r '.node.role' "$ROLE_FILE")"

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

    local stale_files=(
        phoenix-supervisor.json
        phoenix-failover.json
        quic-client-status.json
        quic-responder-status.json
        offsite-heartbeat.json
        mesh-handshake.json
        windows-heartbeat.json
    )

    local file

    for file in "${stale_files[@]}"; do
        rm -f "${TRANS_DIR}/${file}"
    done

    log "Telemetry vacuum complete"
}
 vacuum_telemetry

# ------------------------------------------------------------
# 3. Unit control helpers
# ------------------------------------------------------------
# Helper function to pause until a systemd unit hits the expected state
wait_for_unit_state() {

    local expected="$1"
    local unit="$2"

    local timeout=20
    local i
    local state

    for ((i=0; i<timeout*2; i++)); do

        state=$(
            systemctl show \
                --property=ActiveState \
                --value "$unit" 2>/dev/null
        )

        if [[ "$state" == "$expected" ]]; then
            return 0
        fi

        if [[ "$state" == "failed" ]]; then
            log "CRITICAL: Unit entered failed state: $unit"
            exit 1
        fi

        sleep 0.5
    done

    log "CRITICAL: Timeout waiting for $unit => $expected"
    exit 1
}

# Helper function to validate unit existence
validate_unit_exists() {

    local unit="$1"

    if ! systemctl cat "$unit" >/dev/null 2>&1; then
        log "CRITICAL: Unit does not exist: $unit"
        exit 1
    fi
}

stop_units() {

    local unit

    for unit in "$@"; do
        validate_unit_exists "$unit"
        log "Disabling/stopping: $unit"
        systemctl disable --now "$unit" >/dev/null 2>&1 || true
        wait_for_unit_state "inactive" "$unit"
    done

    sleep 1
}

start_units() {

    local unit

    for unit in "$@"; do

        validate_unit_exists "$unit"
        log "Enabling/starting: $unit"
        systemctl enable --now "$unit" >/dev/null 2>&1 || true
        wait_for_unit_state "active" "$unit"
    done
}


# ------------------------------------------------------------
# 4. Role-specific unit control
# ------------------------------------------------------------

# Common unit sets

COMMON_CONTROLLER_UNITS=(
    semperfix-network-normalizer.service
    semperfix-inotify-monitor.service
    semperfix-phoenix-supervisor.timer
    semperfix-quic-client.timer
    semperfix-phoenix-heartbeat.timer
    semperfix-mesh-status.timer
    semperfix-phoenix-status-write.timer
    semperfix-state-mirror.timer
)

start_common_controller_units() {

    start_units \
        "${COMMON_CONTROLLER_UNITS[@]}"
}

case "$NEW_ROLE" in

    MASTERZERO-ACTIVE)
        stop_units \
            semperfix-quic-responder.service \
            semperfix-phoenix-promote.timer \
            semperfix-phoenix-recovery.timer \
            semperfix-state-export-windows.timer \
            semperfix-phoenix-descalate.timer 

        start_common_controller_units

        start_units \
            semperfix-phoenix-failover.timer
        ;;

    MASTERZERO-DEGRADED)
        stop_units \
            semperfix-phoenix-failover.timer \
            semperfix-quic-responder.service \
            semperfix-phoenix-promote.timer \
            semperfix-phoenix-recovery.timer \
            semperfix-state-export-windows.timer \
            

        start_common_controller_units

        start_units \
            semperfix-phoenix-descalate.timer
        ;;

    MASTERZERO-RECOVER)
        stop_units \
            semperfix-phoenix-failover.timer \
            semperfix-phoenix-descalate.timer \
            semperfix-quic-responder.service \
            semperfix-phoenix-promote.timer \
            semperfix-state-export-windows.timer \
            

        start_common_controller_units

        start_units \
            semperfix-phoenix-recovery.timer
        ;;

    SECONDARY-ACTIVE)
        stop_units \
            semperfix-phoenix-failover.timer \
            semperfix-quic-responder.service \
            semperfix-phoenix-promote.timer \
            semperfix-phoenix-recovery.timer \
            semperfix-mirror-secondary.timer 

        start_common_controller_units

        start_units \
            semperfix-phoenix-descalate.timer
        ;;

    SECONDARY-PASSIVE)
        stop_units \
            semperfix-phoenix-failover.timer \
            semperfix-phoenix-recovery.timer \
            semperfix-phoenix-descalate.timer \
            semperfix-phoenix-supervisor.timer \
            semperfix-quic-client.timer \
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
            semperfix-phoenix-supervisor.timer \
            semperfix-mirror-secondary.service

        start_units \
            semperfix-network-normalizer.service \
            semperfix-inotify-monitor.service \
            semperfix-phoenix-heartbeat.timer \
            semperfix-mesh-status.timer \
            semperfix-state-export-windows.timer
        ;;

esac

log "Phoenix role switch complete: $NEW_ROLE"
exit 0
