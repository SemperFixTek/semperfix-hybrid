#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  SemperFix Syncthing Package v0.1.1-alpha
#  scripts/purge-conflicts.sh
#
#  Finds and removes stale Syncthing conflict files (*.sync-conflict-*) that
#  are older than OLDER_THAN_DAYS. Runs a dry-run first unless --force is
#  passed explicitly.
#
#  Usage:
#    ./purge-conflicts.sh [--force] [--dir /path/to/folder]
#
#  Requires: find
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

# ── Defaults ──────────────────────────────────────────────────────────────────
OLDER_THAN_DAYS="${SEMPERFIX_CONFLICT_DAYS:-14}"
SEARCH_DIR="${SEMPERFIX_SYNC_ROOT:-$HOME/SemperFix}"
LOG_FILE="${SEMPERFIX_LOG_DIR:-$HOME/.semperfix/logs}/purge-conflicts.log"
FORCE=false

# ── Args ──────────────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)      FORCE=true; shift ;;
    --dir)        SEARCH_DIR="$2"; shift 2 ;;
    --days)       OLDER_THAN_DAYS="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

# ── Helpers ───────────────────────────────────────────────────────────────────
log()  { echo "[$(date -Iseconds)] [PURGE] $*" | tee -a "$LOG_FILE"; }
mkdir -p "$(dirname "$LOG_FILE")"

log "Scanning for conflict files in: $SEARCH_DIR"
log "Threshold: older than ${OLDER_THAN_DAYS} days | Force: $FORCE"

# ── Find conflicts ────────────────────────────────────────────────────────────
mapfile -t CONFLICTS < <(
  find "$SEARCH_DIR" \
    -type f \
    -name "*.sync-conflict-*" \
    -mtime +"$OLDER_THAN_DAYS" \
    2>/dev/null | sort
)

COUNT=${#CONFLICTS[@]}
log "Found $COUNT stale conflict file(s)."

if (( COUNT == 0 )); then
  log "Nothing to purge. Exiting cleanly."
  exit 0
fi

# ── Dry-run or live ───────────────────────────────────────────────────────────
if [[ "$FORCE" == "false" ]]; then
  log "DRY-RUN mode (pass --force to actually delete):"
  for f in "${CONFLICTS[@]}"; do
    SIZE=$(du -sh "$f" 2>/dev/null | cut -f1)
    log "  [DRY] Would remove: $f ($SIZE)"
  done
  log "Re-run with --force to execute deletion."
  exit 0
fi

# ── Live deletion ─────────────────────────────────────────────────────────────
REMOVED=0
ERRORS=0
for f in "${CONFLICTS[@]}"; do
  if rm -f "$f" 2>>"$LOG_FILE"; then
    log "  ✔ Removed: $f"
    REMOVED=$((REMOVED+1))
  else
    log "  ✖ Failed to remove: $f"
    ERRORS=$((ERRORS+1))
  fi
done

log "Purge complete. Removed: $REMOVED | Errors: $ERRORS"
(( ERRORS > 0 )) && exit 1 || exit 0
