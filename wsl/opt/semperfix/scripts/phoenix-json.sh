#!/usr/bin/env bash
# =====================================================================
# Phoenix Automation Suite — JSON Writer
# Version: Phoenix v2.1
# Component: phoenix-json
# Role: All roles (controller/responder/offsite)
# Refactor: 2026-10-21 — v2.0 → v2.1 upgrade + optional enhancements
# Maintainer: SemperFix Automation (Bruce)
# =====================================================================

set -euo pipefail

# Safety: prevent Windows CRLF issues
dos2unix "$0" 2>/dev/null || true

# =====================================================================
# JSON Initialization
# =====================================================================
json_init() {
    local file="$1"
    echo "{}" > "$file"
}

# =====================================================================
# Set a string value (atomic)
# =====================================================================
json_set() {
    local file="$1"
    local key="$2"
    local value="$3"

    # mktemp inside same directory ensures correct ownership + avoids cross-FS rename issues
    local tmp
    tmp="$(mktemp "${file}.XXXX")"

    jq --arg k "$key" --arg v "$value" '.[$k] = $v' "$file" > "$tmp"
    mv "$tmp" "$file"
}

# =====================================================================
# Set a raw JSON value (arrays, objects)
# =====================================================================
json_set_raw() {
    local file="$1"
    local key="$2"
    local raw="$3"

    local tmp
    tmp="$(mktemp "${file}.XXXX")"

    jq --arg k "$key" --argjson r "$raw" '.[$k] = $r' "$file" > "$tmp"
    mv "$tmp" "$file"
}

# =====================================================================
# Finalize JSON (normalize, pretty‑print)
# =====================================================================
json_finalize() {
    local file="$1"

    local tmp
    tmp="$(mktemp "${file}.XXXX")"

    jq '.' "$file" > "$tmp"
    mv "$tmp" "$file"
}
