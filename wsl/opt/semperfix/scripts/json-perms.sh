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

target="$1"

chown root:semperfix "$target"
chmod 664 "$target"
