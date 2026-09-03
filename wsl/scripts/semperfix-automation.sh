#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  SemperFix Syncthing Package v0.1.1-alpha
#  scripts/semperfix-automation.sh
#
#  Central automation runner. Orchestrates all SemperFix hooks on a schedule
#  or on demand. Designed to be called from cron or a systemd timer.
#
#  Usage:
#    ./semperfix-automation.sh [health|backup|rotate|purge|all]
#
#  Cron example (run all checks every 15 minutes):
#    */15 * * * * /home/user/.semperfix/scripts/semperfix-automation.sh all
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SEMPERFIX_LOG_DIR:-$HOME/.semperfix/logs}/automation.log"
mkdir -p "$(dirname "$LOG_FILE")"

log()  { echo "[$(date -Iseconds)] [AUTO] $*" | tee -a "$LOG_FILE"; }
run()  {
  local name="$1"; local script="$2"; shift 2
  log "→ Running: $name"
  if bash "$SCRIPT_DIR/$script" "$@" >> "$LOG_FILE" 2>&1; then
    log "  ✔ $name completed"
  else
    log "  ✖ $name failed (exit $?)"
  fi
}

CMD="${1:-all}"

case "$CMD" in
  health)  run "Health Check"        health-check.sh ;;
  backup)  run "Config Backup"       backup-config.sh ;;
  rotate)  run "Log Rotation"        rotate-logs.sh ;;
  purge)   run "Conflict Purge"      purge-conflicts.sh ;;
  all)
    run "Health Check"    health-check.sh
    run "Log Rotation"    rotate-logs.sh
    run "Conflict Purge"  purge-conflicts.sh
    # Backup only runs at night (02:xx hour) when called via 'all'
    HOUR=$(date +%H)
    if (( 10#$HOUR == 2 )); then
      run "Config Backup" backup-config.sh
    else
      log "  ⏭ Config Backup skipped (runs at 02:xx)"
    fi
    ;;
  *)
    echo "Usage: $0 [health|backup|rotate|purge|all]" >&2
    exit 1
    ;;
esac

log "Automation run complete."
