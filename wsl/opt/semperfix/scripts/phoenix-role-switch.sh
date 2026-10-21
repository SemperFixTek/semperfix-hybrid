#!/usr/bin/env bash
set -euo pipefail

umask 002
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

ROLE_FILE="/opt/semperfix/state/phoenix.json"
PRESET_DIR="/etc/systemd/system-preset"

log() {
    echo "[ROLE-SWITCH] $*" >&2
}

usage() {
    echo "Usage: $0 <MASTERZERO-ACTIVE|MASTERZERO-DEGRADED|MASTERZERO-RECOVER|SECONDARY-ACTIVE|SECONDARY-PASSIVE|OFFSITE>"
    exit 1
}

# --- Validate input ---
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

# --- Update phoenix.json ---
log "Updating phoenix.json"
jq --arg role "$NEW_ROLE" '.role = $role' "$ROLE_FILE" > "${ROLE_FILE}.tmp"
mv "${ROLE_FILE}.tmp" "$ROLE_FILE"

# --- Apply correct preset ---
PRESET_FILE="${PRESET_DIR}/90-semperfix-${NEW_ROLE,,}.preset"

if [[ ! -f "$PRESET_FILE" ]]; then
    log "ERROR: Preset file not found: $PRESET_FILE"
    exit 1
fi

log "Applying preset: $PRESET_FILE"
systemctl preset-all

# --- Reload systemd ---
log "Reloading systemd daemon"
systemctl daemon-reload

# --- Restart role-aware services ---
log "Restarting Phoenix heartbeat + mesh-status"
systemctl restart semperfix-phoenix-heartbeat.timer
systemctl restart semperfix-mesh-status.timer

# --- Special-case logic ---
case "$NEW_ROLE" in
    SECONDARY-ACTIVE)
        log "SECONDARY promoted — starting supervisor + failover"
        systemctl restart semperfix-phoenix-supervisor.timer
        systemctl restart semperfix-phoenix-failover.timer
        ;;
    SECONDARY-PASSIVE)
        log "SECONDARY demoted — enabling QUIC responder"
        systemctl restart semperfix-quic-responder.service
        ;;
    MASTERZERO-RECOVER)
        log "MASTERZERO recovery mode — restarting descalate engine"
        systemctl restart semperfix-phoenix-descalate.timer
        ;;
esac

log "Phoenix role switch complete: $NEW_ROLE"
exit 0
