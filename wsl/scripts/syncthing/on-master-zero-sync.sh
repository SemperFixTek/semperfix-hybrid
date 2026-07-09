#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  SemperFix Syncthing Package v0.1.1-alpha
#  scripts/on-master-zero-sync.sh
#
#  Post-sync hook invoked after Master Zero (send-only) folder completes
#  a sync cycle. Wire this into Syncthing's "on sync completion" event via
#  the SemperFix automation runner or a custom wrapper.
#
#  Environment variables provided by caller:
#    SEMPERFIX_FOLDER_ID   — folder ID that triggered the hook
#    SEMPERFIX_FOLDER_PATH — local path of the synced folder
#    SEMPERFIX_DEVICE_ID   — device that completed sync (if applicable)
#
#  Requires: curl, jq (optional for advanced event parsing)
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

FOLDER_ID="${SEMPERFIX_FOLDER_ID:-master-zero}"
FOLDER_PATH="${SEMPERFIX_FOLDER_PATH:-$HOME/SemperFix/MasterZero}"
LOG_FILE="${SEMPERFIX_LOG_DIR:-$HOME/.semperfix/logs}/master-zero-sync.log"
WEBHOOK_URL="${SEMPERFIX_WEBHOOK_URL:-}"        # Optional: POST sync event here
REPORT_FILE="${SEMPERFIX_REPORT_DIR:-$HOME/.semperfix/reports}/master-zero-last-sync.json"

log()  { echo "[$(date -Iseconds)] [HOOK:master-zero] $*" | tee -a "$LOG_FILE"; }
mkdir -p "$(dirname "$LOG_FILE")" "$(dirname "$REPORT_FILE")"

log "Sync cycle complete for folder '$FOLDER_ID' at $FOLDER_PATH"

# ── 1. Count synced items ─────────────────────────────────────────────────────
TOTAL_FILES=$(find "$FOLDER_PATH" -type f 2>/dev/null | wc -l | tr -d ' ')
TOTAL_DIRS=$(find "$FOLDER_PATH" -type d 2>/dev/null | wc -l | tr -d ' ')
DISK_USAGE=$(du -sh "$FOLDER_PATH" 2>/dev/null | cut -f1)

log "  Files: $TOTAL_FILES | Dirs: $TOTAL_DIRS | Disk: $DISK_USAGE"

# ── 2. Write sync report ──────────────────────────────────────────────────────
REPORT_TIMESTAMP=$(date -Iseconds)
cat > "$REPORT_FILE" <<JSON
{
  "folder":    "$FOLDER_ID",
  "path":      "$FOLDER_PATH",
  "timestamp": "$REPORT_TIMESTAMP",
  "fileCount": $TOTAL_FILES,
  "dirCount":  $TOTAL_DIRS,
  "diskUsage": "$DISK_USAGE"
}
JSON
log "  ✔ Report written: $REPORT_FILE"

# ── 3. Verify no unexpected receive-side changes ──────────────────────────────
# Master Zero is send-only; flag if any locally unexpected .sync-conflict files exist
CONFLICTS=$(find "$FOLDER_PATH" -name "*.sync-conflict-*" 2>/dev/null | wc -l | tr -d ' ')
if (( CONFLICTS > 0 )); then
  log "  ⚠ WARNING: $CONFLICTS conflict file(s) found in send-only Master Zero folder."
  log "    Run scripts/purge-conflicts.sh --dir '$FOLDER_PATH' --force to clean up."
fi

# ── 4. Optional webhook notification ─────────────────────────────────────────
if [[ -n "$WEBHOOK_URL" ]]; then
  PAYLOAD=$(cat "$REPORT_FILE")
  HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST "$WEBHOOK_URL" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD" \
    --max-time 10 || echo "000")
  if [[ "$HTTP_STATUS" == "200" || "$HTTP_STATUS" == "204" ]]; then
    log "  ✔ Webhook notified ($HTTP_STATUS)"
  else
    log "  ⚠ Webhook returned HTTP $HTTP_STATUS — notification may have failed"
  fi
fi

log "Hook complete."
