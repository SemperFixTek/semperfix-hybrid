#!/usr/bin/env bash
set -euo pipefail

HB_PATH="/mnt/c/SemperFix/ConfigBackup/phoenix-heartbeat.json"

TS="$(date --iso-8601=seconds)"

cat > "$HB_PATH" <<EOF
{
  "Timestamp": "$TS"
}
EOF

cat "$HB_PATH"
