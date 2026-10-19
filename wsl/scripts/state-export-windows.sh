#!/usr/bin/env bash
set -euo pipefail

SRC="/var/lib/semperfix/state/export"
DST="/mnt/c/semperfix/secondary"

# Ensure destination exists
mkdir -p "$DST"

# Copy JSON files from WSL → Windows NTFS
cp "$SRC"/*.json "$DST"/ 2>/dev/null || true

# Optional: fix Windows-side permissions (helps Syncthing)
chmod 666 "$DST"/*.json 2>/dev/null || true
