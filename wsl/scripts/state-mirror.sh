#!/usr/bin/env bash
set -euo pipefail

SRC="/mnt/c/semperfix/secondary"
DST="/var/lib/semperfix/state/secondary"

# Fix permissions (Syncthing sometimes resets them)
chown -R sfx:semperfix "$DST" || true
chmod -R 775 "$DST" || true
