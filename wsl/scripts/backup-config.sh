#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  SemperFix Syncthing Package v0.1.1-alpha
#  scripts/backup-config.sh
#
#  Creates a timestamped backup of the Syncthing configuration directory and
#  the SemperFix config overlay, then prunes backups older than RETAIN_DAYS.
#
#  Intended to run via cron: 0 2 * * * /path/to/backup-config.sh
#
#  Requires: tar, find
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

# ── Configuration ─────────────────────────────────────────────────────────────
ST_CONFIG_DIR="${SYNCTHING_HOME:-$HOME/.config/syncthing}"
SEMPERFIX_CONFIG_DIR="${SEMPERFIX_CONFIG_DIR:-$HOME/.semperfix}"
BACKUP_DEST="${SEMPERFIX_BACKUP_DEST:-$HOME/SemperFix/ConfigBackup}"
RETAIN_DAYS="${SEMPERFIX_BACKUP_RETAIN_DAYS:-30}"
LOG_FILE="${SEMPERFIX_LOG_DIR:-$HOME/.semperfix/logs}/backup-config.log"
TIMESTAMP=$(date +"%Y%m%dT%H%M%S")
ARCHIVE_NAME="semperfix-config-backup-${TIMESTAMP}.tar.gz"

# ── Helpers ───────────────────────────────────────────────────────────────────
log()  { echo "[$(date -Iseconds)] [BACKUP] $*" | tee -a "$LOG_FILE"; }
fail() { echo "[$(date -Iseconds)] [ERROR]  $*" | tee -a "$LOG_FILE" >&2; exit 1; }

mkdir -p "$BACKUP_DEST" "$(dirname "$LOG_FILE")"

# ── Validate source directories ───────────────────────────────────────────────
[[ -d "$ST_CONFIG_DIR" ]] || fail "Syncthing config dir not found: $ST_CONFIG_DIR"

log "Starting config backup → $BACKUP_DEST/$ARCHIVE_NAME"

# ── Create archive ────────────────────────────────────────────────────────────
SOURCES=("$ST_CONFIG_DIR")
[[ -d "$SEMPERFIX_CONFIG_DIR" ]] && SOURCES+=("$SEMPERFIX_CONFIG_DIR")

tar \
  --exclude="*.tmp" \
  --exclude=".stversions" \
  --exclude="index-*.db" \
  -czf "$BACKUP_DEST/$ARCHIVE_NAME" \
  "${SOURCES[@]}" \
  2>>"$LOG_FILE"

SIZE=$(du -sh "$BACKUP_DEST/$ARCHIVE_NAME" | cut -f1)
log "  ✔ Archive created: $ARCHIVE_NAME ($SIZE)"

# ── Checksum ──────────────────────────────────────────────────────────────────
sha256sum "$BACKUP_DEST/$ARCHIVE_NAME" > "$BACKUP_DEST/${ARCHIVE_NAME}.sha256"
log "  ✔ SHA-256 written: ${ARCHIVE_NAME}.sha256"

# ── Prune old backups ─────────────────────────────────────────────────────────
log "Pruning backups older than ${RETAIN_DAYS} days ..."
PRUNED=0
while IFS= read -r old_file; do
  rm -f "$old_file" "${old_file}.sha256"
  log "  ↳ Removed: $(basename "$old_file")"
  PRUNED=$((PRUNED+1))
done < <(find "$BACKUP_DEST" -maxdepth 1 -name "semperfix-config-backup-*.tar.gz" \
           -mtime +"$RETAIN_DAYS" 2>/dev/null || true)

log "Pruned $PRUNED old backup(s). Done."
