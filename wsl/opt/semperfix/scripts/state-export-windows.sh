#!/usr/bin/env bash
# =====================================================================
# Phoenix Automation Suite — State Export (Windows)
# Version: Phoenix v2.1
# Component: wsl-state-export-windows
# Role: Controller / Responder / Observer (role-aware)
# Refactor: 2026-10-21 — v2.0 → v2.1 role model upgrade
# Maintainer: SemperFix Automation (Bruce)
# =====================================================================

set -euo pipefail

umask 002
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

dos2unix "$0" 2>/dev/null || true

source /opt/semperfix/scripts/phoenix-core.sh
phoenix_init

LOGFILE="${LOG_DIR}/export-state.log"
PHOENIX_LOGFILE="$LOGFILE"

log() { phoenix_log_file INFO "$*"; }

STATUS_JSON="${STATE_DIR}/phoenix-status.json"
SRC_DIR="${STATE_DIR}"
DEST_DIR="/mnt/c/semperfix/secondary"
WIN_STATE="/mnt/c/semperfix/state"

mkdir -p "$DEST_DIR"

get_role() {
    if [[ -f "$STATUS_JSON" ]]; then
        jq -r '.Role // "UNKNOWN"' "$STATUS_JSON" 2>/dev/null || echo "UNKNOWN"
    else
        echo "UNKNOWN"
    fi
}

ROLE="$(get_role)"
log "Export starting. Detected node role: $ROLE"
log "Source: $SRC_DIR  Destination: $DEST_DIR"

export_passive() {
    log "Role SECONDARY-PASSIVE: exporting passive telemetry only"

    cp "$SRC_DIR"/phoenix-heartbeat.json      "$DEST_DIR"/ 2>/dev/null || true
    cp "$SRC_DIR"/mesh-status.json            "$DEST_DIR"/ 2>/dev/null || true
    cp "$SRC_DIR"/quic-client-status.json     "$DEST_DIR"/ 2>/dev/null || true
    cp "$WIN_STATE"/windows-heartbeat.json    "$DEST_DIR"/ 2>/dev/null || true
}

export_active() {
    log "Role SECONDARY-ACTIVE: exporting full controller telemetry"

    cp "$SRC_DIR"/phoenix-heartbeat.json      "$DEST_DIR"/ 2>/dev/null || true
    cp "$SRC_DIR"/mesh-status.json            "$DEST_DIR"/ 2>/dev/null || true
    cp "$SRC_DIR"/quic-client-status.json     "$DEST_DIR"/ 2>/dev/null || true
    cp "$SRC_DIR"/phoenix-supervisor.json     "$DEST_DIR"/ 2>/dev/null || true
    cp "$SRC_DIR"/phoenix-failover.json       "$DEST_DIR"/ 2>/dev/null || true
    cp "$WIN_STATE"/windows-heartbeat.json    "$DEST_DIR"/ 2>/dev/null || true
}

case "$ROLE" in
    SECONDARY-PASSIVE)
        export_passive
        ;;
    SECONDARY-ACTIVE)
        export_active
        ;;
    *)
        log "Unknown or non-secondary role ($ROLE). Exporting passive baseline only."
        export_passive
        ;;
esac

chmod 664 "$DEST_DIR"/*.json 2>/dev/null || true
chown sfx:semperfix "$DEST_DIR"/*.json 2>/dev/null || true

log "Export completed. Files now in Windows NTFS:"
ls -l "$DEST_DIR"/*.json 2>/dev/null || true
