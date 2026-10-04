#!/usr/bin/env bash
set -euo pipefail

# Phoenix v2 Standard Environment Header
umask 002

# Ensure consistent locale + predictable JSON behavior
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

# Ensure logs and state directories exist
mkdir -p /var/lib/semperfix/state
mkdir -p /opt/semperfix/logs

# Safety: prevent Windows CRLF issues
dos2unix "$0" 2>/dev/null || true


source /opt/semperfix/scripts/phoenix-core.sh
source /opt/semperfix/scripts/phoenix-json.sh
phoenix_load_config

STATE_DIR="/var/lib/semperfix/state"
LOG_DIR="/opt/semperfix/logs"

SUP_FILE="${STATE_DIR}/phoenix-supervisor.json"
LOGFILE="${LOG_DIR}/phoenix-supervisor.log"

mkdir -p "$STATE_DIR" "$LOG_DIR"

log() {
    echo "[INFO] $1" | tee -a "$LOGFILE"
}

run_handshake() {
    /opt/semperfix/scripts/wsl-mesh-handshake.sh || return 1
}

run_verify() {
    /opt/semperfix/scripts/wsl-mesh-verify.sh || return 1
}

run_activate() {
    /opt/semperfix/scripts/wsl-mesh-activate.sh || return 1
}

main() {
    : > "$LOGFILE"
    log "Starting Phoenix v2 Supervisor"

    local handshake_status verify_status activate_status

    if run_handshake; then
        handshake_status="pass"
    else
        handshake_status="fail"
    fi

    if run_verify; then
        verify_status="pass"
    else
        verify_status="fail"
    fi

    if run_activate; then
        activate_status="pass"
    else
        activate_status="fail"
    fi

    # ---------- Unified JSON Writer ----------
    json_init "$SUP_FILE"

    json_set "$SUP_FILE" "timestamp" "$(date -Iseconds)"
    json_set "$SUP_FILE" "handshake_status" "$handshake_status"
    json_set "$SUP_FILE" "verify_status" "$verify_status"
    json_set "$SUP_FILE" "activate_status" "$activate_status"

    # Backward‑compatibility fields
    json_set "$SUP_FILE" "handshake" "$handshake_status"
    json_set "$SUP_FILE" "verify" "$verify_status"
    json_set "$SUP_FILE" "activate" "$activate_status"

    json_finalize "$SUP_FILE"

    log "Supervisor state written to $SUP_FILE"
}

main "$@"
