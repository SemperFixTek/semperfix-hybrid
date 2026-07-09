#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  SemperFix Syncthing Package v0.1.1-alpha
#  scripts/rotate-logs.sh
#
#  Rotates SemperFix log files when they exceed MAX_SIZE_MB.
#  Keeps up to KEEP_FILES rotated copies, then deletes the oldest.
#
#  Requires: find, awk
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

LOG_DIR="${SEMPERFIX_LOG_DIR:-$HOME/.semperfix/logs}"
MAX_SIZE_MB="${SEMPERFIX_LOG_MAX_MB:-50}"
KEEP_FILES="${SEMPERFIX_LOG_KEEP:-7}"
TIMESTAMP=$(date +"%Y%m%dT%H%M%S")

mkdir -p "$LOG_DIR"

rotate_if_needed() {
  local log_file="$1"
  [[ -f "$log_file" ]] || return 0

  local size_kb
  size_kb=$(du -k "$log_file" | awk '{print $1}')
  local max_kb=$(( MAX_SIZE_MB * 1024 ))

  if (( size_kb >= max_kb )); then
    local rotated="${log_file}.${TIMESTAMP}"
    mv "$log_file" "$rotated"
    gzip -q "$rotated" && rotated="${rotated}.gz"
    touch "$log_file"
    echo "[$(date -Iseconds)] [ROTATE] Rotated $(basename "$log_file") → $(basename "$rotated")"

    # Prune oldest rotations beyond KEEP_FILES
    local base
    base=$(basename "$log_file")
    mapfile -t old_files < <(
      find "$LOG_DIR" -maxdepth 1 -name "${base}.*.gz" | sort | head -n -"$KEEP_FILES"
    )
    for old in "${old_files[@]}"; do
      rm -f "$old"
      echo "[$(date -Iseconds)] [ROTATE] Pruned old log: $(basename "$old")"
    done
  fi
}

for log_file in "$LOG_DIR"/*.log; do
  rotate_if_needed "$log_file"
done

echo "[$(date -Iseconds)] [ROTATE] Log rotation complete."
