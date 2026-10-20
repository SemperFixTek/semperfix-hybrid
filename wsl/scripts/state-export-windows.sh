#!/usr/bin/env bash
set -euo pipefail


umask 002
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

# Safety: prevent CRLF issues
dos2unix "$0" 2>/dev/null || true

# Load Phoenix core + JSON helpers
source /opt/semperfix/scripts/phoenix-core.sh
phoenix_init

LOGFILE="${LOG_DIR}/export-state.log"

STAGING_DIR="${STATE_DIR}/export"
DEST_DIR="/mnt/c/semperfix/secondary"
WIN_HB="/mnt/c/semperfix/state"

# Ensure destination exists
mkdir -p "$DEST_DIR"

PHOENIX_LOGFILE="${LOGFILE}"
log() {
    phoenix_log_file INFO "$*"
}

# Collect and stage JSON files for export
log "Staging state JSON files from ${STATE_DIR} to $STAGING_DIR"

cp $WIN_HB/windows-heartbeat.json "$STAGING_DIR"/ 2>/dev/null || true
cp $STATE_DIR/*.json "$STAGING_DIR"/ 2>/dev/null || true

log "Files staged for export"

# Copy JSON files from WSL → Windows NTFS
log "Exporting JSON files to Windows NTFS at $DEST_DIR"
cp "$STAGING_DIR"/*.json "$DEST_DIR"/ 2>/dev/null || true

# Optional: fix Windows-side permissions (helps Syncthing)
log "Setting permissions on exported JSON files"
chown sfx:semperfix "$DEST_DIR"/*.json 2>/dev/null || true
chmod 755 "$DEST_DIR"/*.json 2>/dev/null || true

log "Export completed. Exported files:"
ls -l "$DEST_DIR"/*.json 2>/dev/null || true