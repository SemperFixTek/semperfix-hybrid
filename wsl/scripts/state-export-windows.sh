#!/usr/bin/env bash
set -euo pipefail


# Load Phoenix core + JSON helpers
source /opt/semperfix/scripts/phoenix-core.sh
source /opt/semperfix/scripts/phoenix-json.sh
phoenix_init

LOGFILE="${LOG_DIR}/export-state.log"

SRC="${STATE_DIR}/export"
DST="/mnt/c/semperfix/secondary"
WIN_HB="/mnt/c/semperfix/state"
# Ensure destination exists
mkdir -p "$DST"

PHOENIX_LOGFILE="${LOGFILE}"
log() {
    phoenix_log_file INFO "$*"
}

# EXPORT_DIR="/var/lib/semperfix/state/export"
log "Staging state JSON files from ${STATE_DIR} to $SRC"

cp $WIN_HB/windows-heartbeat.json "$SRC"/ 2>/dev/null || true
cp $STATE_DIR/*.json "$SRC"/ 2>/dev/null || true

#cp /var/lib/semperfix/state/phoenix-heartbeat.json "$SRC/" || true
#cp /var/lib/semperfix/state/phoenix-supervisor.json "$SRC/" || true
#cp /var/lib/semperfix/state/mesh-status.json "$SRC/" || true
#cp /var/lib/semperfix/state/quic-client-status.json "$SRC/" || true
#cp /var/lib/semperfix/state/phoenix-failover.json "$SRC/" || true
#cp /var/lib/semperfix/state/windows-heartbeat.json "$SRC/" || true

log "Files staged for export"

# Copy JSON files from WSL → Windows NTFS
log "Exporting JSON files to Windows NTFS at $DST"
cp "$SRC"/*.json "$DST"/ 2>/dev/null || true

# Optional: fix Windows-side permissions (helps Syncthing)
log "Setting permissions on exported JSON files"
chown sfx:semperfix "$DST"/*.json 2>/dev/null || true
chmod 755 "$DST"/*.json 2>/dev/null || true

log "Export completed. Exported files:"
ls -l "$DST"/*.json 2>/dev/null || true