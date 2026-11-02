#!/usr/bin/env bash

# =====================================================================
# Phoenix Automation Suite — JSON Perms
# Version: Phoenix v2.1
# Component: json-perms
# Role: Controller / Responder
# Refactor: 2026-10-21 — v2.0 → v2.1 role model upgrade
# Maintainer: SemperFix Automation (Bruce)
# =====================================================================
set -euo pipefail

umask 002
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

dos2unix "$0" 2>/dev/null || true

target="$1"

chown root:semperfix "$target"
chmod 664 "$target"
