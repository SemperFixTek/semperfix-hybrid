#!/usr/bin/env bash
# =====================================================================
# Phoenix Automation Suite — State Mirror (Secondary)
# Version: Phoenix v2.1
# Component: wsl-state-mirror-secondary
# Role: Secondary (role-aware)
# Refactor: 2026-10-21 — v2.0 → v2.1 role model upgrade
# Maintainer: SemperFix Automation (Bruce)
# =====================================================================

set -euo pipefail

SRC="/mnt/c/semperfix/secondary"
DST="/var/lib/semperfix/state/secondary"

# Ensure destination exists
mkdir -p "$DST"

# Copy JSON from Windows NTFS → WSL
cp "$SRC"/*.json "$DST"/ 2>/dev/null || true

# Fix permissions for WSL consumers (dashboard, mesh, etc.)
chown sfx:semperfix "$DST"/*.json 2>/dev/null || true
chmod 664 "$DST"/*.json 2>/dev/null || true
