#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  SemperFix Syncthing Package v0.1.1-alpha
#  scripts/health-check.sh
#
#  Polls the Syncthing REST API and verifies:
#    • GUI / API reachability
#    • All configured folders are "idle" or "scanning" (not "error")
#    • No device has been disconnected for longer than STALE_MINUTES
#    • Disk free % is above the configured threshold
#
#  Exit codes:
#    0 — all checks passed
#    1 — one or more checks failed (details printed to stderr)
#
#  Requires: curl, jq
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

# ── Configuration ─────────────────────────────────────────────────────────────
ST_HOST="${SEMPERFIX_ST_HOST:-http://127.0.0.1:8384}"
ST_APIKEY="${SEMPERFIX_ST_APIKEY:-}"          # Set via env or ~/.semperfix/env
STALE_MINUTES="${SEMPERFIX_STALE_MINUTES:-30}"
MIN_DISK_PCT="${SEMPERFIX_MIN_DISK_PCT:-5}"
LOG_FILE="${SEMPERFIX_LOG_DIR:-$HOME/.semperfix/logs}/health-check.log"
ALERT_SCRIPT="${SEMPERFIX_ALERT_SCRIPT:-}"    # Optional: path to alert script

# ── Helpers ───────────────────────────────────────────────────────────────────
log()   { echo "[$(date -Iseconds)] [HEALTH] $*" | tee -a "$LOG_FILE"; }
warn()  { echo "[$(date -Iseconds)] [WARN]   $*" | tee -a "$LOG_FILE" >&2; }
fail()  { echo "[$(date -Iseconds)] [FAIL]   $*" | tee -a "$LOG_FILE" >&2; FAILURES=$((FAILURES+1)); }
alert() {
  local msg="$1"
  log "ALERT: $msg"
  if [[ -n "$ALERT_SCRIPT" && -x "$ALERT_SCRIPT" ]]; then
    "$ALERT_SCRIPT" "$msg" || true
  fi
}

mkdir -p "$(dirname "$LOG_FILE")"
FAILURES=0

# ── Dependency check ──────────────────────────────────────────────────────────
for cmd in curl jq; do
  if ! command -v "$cmd" &>/dev/null; then
    fail "Required command not found: $cmd"
    exit 1
  fi
done

# ── API key ───────────────────────────────────────────────────────────────────
if [[ -z "$ST_APIKEY" ]]; then
  ENV_FILE="$HOME/.semperfix/env"
  if [[ -f "$ENV_FILE" ]]; then
    # shellcheck source=/dev/null
    source "$ENV_FILE"
    ST_APIKEY="${SEMPERFIX_ST_APIKEY:-}"
  fi
fi
if [[ -z "$ST_APIKEY" ]]; then
  fail "ST_APIKEY not set. Export SEMPERFIX_ST_APIKEY or add it to ~/.semperfix/env"
  exit 1
fi

CURL_OPTS=(-s -f --max-time 10 -H "X-API-Key: $ST_APIKEY")

# ── 1. Reachability ───────────────────────────────────────────────────────────
log "Checking Syncthing reachability at $ST_HOST ..."
if ! curl "${CURL_OPTS[@]}" "$ST_HOST/rest/system/ping" | jq -e '.ping == "pong"' &>/dev/null; then
  fail "Syncthing API unreachable at $ST_HOST"
  alert "Syncthing API unreachable — service may be down"
  exit 1
fi
log "  ✔ API reachable"

# ── 2. Folder status ──────────────────────────────────────────────────────────
log "Checking folder states ..."
FOLDER_STATUS=$(curl "${CURL_OPTS[@]}" "$ST_HOST/rest/db/completion" 2>/dev/null || echo "{}")
FOLDERS_JSON=$(curl "${CURL_OPTS[@]}" "$ST_HOST/rest/config/folders" 2>/dev/null || echo "[]")

while IFS= read -r folder_id; do
  STATE=$(curl "${CURL_OPTS[@]}" "$ST_HOST/rest/db/status?folder=$folder_id" 2>/dev/null \
    | jq -r '.state // "unknown"')
  if [[ "$STATE" == "error" ]]; then
    fail "Folder '$folder_id' is in ERROR state"
    alert "Folder $folder_id entered error state"
  elif [[ "$STATE" == "unknown" ]]; then
    warn "Folder '$folder_id' state could not be determined"
  else
    log "  ✔ Folder '$folder_id' state: $STATE"
  fi
done < <(echo "$FOLDERS_JSON" | jq -r '.[].id')

# ── 3. Device connectivity ────────────────────────────────────────────────────
log "Checking device connectivity (stale threshold: ${STALE_MINUTES}m) ..."
CONNECTIONS=$(curl "${CURL_OPTS[@]}" "$ST_HOST/rest/system/connections" 2>/dev/null \
  | jq -r '.connections // {}')
STALE_SEC=$((STALE_MINUTES * 60))
NOW_EPOCH=$(date +%s)

while IFS= read -r device_id; do
  CONNECTED=$(echo "$CONNECTIONS" | jq -r --arg d "$device_id" '.[$d].connected // false')
  if [[ "$CONNECTED" == "false" ]]; then
    LAST_SEEN_RAW=$(echo "$CONNECTIONS" | jq -r --arg d "$device_id" '.[$d].lastSeen // ""')
    if [[ -n "$LAST_SEEN_RAW" ]]; then
      LAST_SEEN_EPOCH=$(date -d "$LAST_SEEN_RAW" +%s 2>/dev/null || echo 0)
      DELTA=$((NOW_EPOCH - LAST_SEEN_EPOCH))
      if (( DELTA > STALE_SEC )); then
        fail "Device '$device_id' disconnected for $((DELTA/60))m (threshold: ${STALE_MINUTES}m)"
        alert "Device $device_id has been offline for $((DELTA/60)) minutes"
      else
        warn "Device '$device_id' disconnected but within stale window ($((DELTA/60))m)"
      fi
    else
      warn "Device '$device_id' never connected or last-seen unavailable"
    fi
  else
    log "  ✔ Device '$device_id' connected"
  fi
done < <(echo "$CONNECTIONS" | jq -r 'keys[]')

# ── 4. Disk space ─────────────────────────────────────────────────────────────
log "Checking disk space (min: ${MIN_DISK_PCT}%) ..."
SYSTEM_STATUS=$(curl "${CURL_OPTS[@]}" "$ST_HOST/rest/system/status" 2>/dev/null || echo "{}")
DISK_FREE=$(echo "$SYSTEM_STATUS" | jq -r '.diskFree // 0')
DISK_TOTAL=$(echo "$SYSTEM_STATUS" | jq -r '.diskTotal // 1')
if (( DISK_TOTAL > 0 )); then
  DISK_PCT=$(echo "scale=1; $DISK_FREE * 100 / $DISK_TOTAL" | bc)
  DISK_INT=${DISK_PCT%.*}
  if (( DISK_INT < MIN_DISK_PCT )); then
    fail "Disk free ${DISK_PCT}% is below threshold ${MIN_DISK_PCT}%"
    alert "Low disk space: ${DISK_PCT}% free on Syncthing host"
  else
    log "  ✔ Disk free: ${DISK_PCT}%"
  fi
fi

# ── Result ────────────────────────────────────────────────────────────────────
if (( FAILURES > 0 )); then
  log "Health check FAILED with $FAILURES failure(s). See $LOG_FILE"
  exit 1
else
  log "Health check PASSED — all systems nominal."
  exit 0
fi
