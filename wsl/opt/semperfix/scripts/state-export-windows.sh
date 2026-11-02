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
TRANS_DIR="$STATE_DIR/transfer"
DEST_DIR="/mnt/c/semperfix/secondary"
WIN_STATE="/mnt/c/semperfix/state"

mkdir -p "$DEST_DIR"
mkdir -p "$TRANS_DIR"

get_role() {
    if [[ -f "$STATUS_JSON" ]]; then
        jq -r '.node.role // "UNKNOWN"' "$STATUS_JSON" 2>/dev/null || echo "UNKNOWN"
    else
        echo "UNKNOWN"
    fi
}

transfer_export() {
    cp "$SRC_DIR"/phoenix-heartbeat.json      "$TRANS_DIR"/ 2>/dev/null || true
    cp "$SRC_DIR"/mesh-status.json            "$TRANS_DIR"/ 2>/dev/null || true
    cp "$SRC_DIR"/quic-client-status.json     "$TRANS_DIR"/ 2>/dev/null || true
    cp "$SRC_DIR"/phoenix-supervisor.json     "$TRANS_DIR"/ 2>/dev/null || true
    cp "$SRC_DIR"/phoenix-failover.json       "$TRANS_DIR"/ 2>/dev/null || true
    cp "$WIN_STATE"/windows-heartbeat.json    "$TRANS_DIR"/ 2>/dev/null || true
    
}
transfer_export

ROLE="$(get_role)"
log "Export starting. Detected node role: $ROLE"
log "Source: $TRANS_DIR  Destination: $DEST_DIR"

export_passive() {
    log "Role SECONDARY-PASSIVE: exporting passive telemetry only"

    cp "$TRANS_DIR"/phoenix-heartbeat.json      "$DEST_DIR"/ 2>/dev/null || true
    cp "$TRANS_DIR"/mesh-status.json            "$DEST_DIR"/ 2>/dev/null || true
#   cp "$TRANS_DIR"/quic-client-status.json     "$DEST_DIR"/ 2>/dev/null || true
    cp "$TRANS_DIR"/windows-heartbeat.json      "$DEST_DIR"/ 2>/dev/null || true
    rm "$TRANS_DIR"/phoenix-supervisor.json 2>/dev/null || true
    rm "$TRANS_DIR"/phoenix-failover.json 2>/dev/null || true
}   

export_active() {
    log "Role SECONDARY-ACTIVE: exporting full controller telemetry"

    cp "$TRANS_DIR"/phoenix-heartbeat.json      "$DEST_DIR"/ 2>/dev/null || true
    cp "$TRANS_DIR"/mesh-status.json            "$DEST_DIR"/ 2>/dev/null || true
    cp "$TRANS_DIR"/quic-client-status.json     "$DEST_DIR"/ 2>/dev/null || true
    cp "$TRANS_DIR"/phoenix-supervisor.json     "$DEST_DIR"/ 2>/dev/null || true
    cp "$TRANS_DIR"/phoenix-failover.json       "$DEST_DIR"/ 2>/dev/null || true
    cp "$TRANS_DIR"/windows-heartbeat.json      "$DEST_DIR"/ 2>/dev/null || true
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
