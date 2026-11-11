#!/usr/bin/env bash
# =====================================================================
# Phoenix Automation Suite — JSON Writer
# Version: Phoenix v2.1
# Component: phoenix-json
# Role: All roles (controller/responder/offsite)
# Refactor: 2026-11-06 — v2.1 → v2.1.1 upgrade + optional enhancements
# Maintainer: SemperFix Automation (Bruce)
# =====================================================================

set -euo pipefail

umask 002

export LC_ALL=C.UTF-8
export LANG=C.UTF-8

# =====================================================================
# JSON Initialization
# =====================================================================

json_init() {

    local file="$1"

    printf '{}\n' > "$file"
}

# =====================================================================
# Set String Value
# =====================================================================

json_set() {

    local file="$1"
    local key="$2"
    local value="$3"

    local tmp

    tmp="$(mktemp "${file}.XXXX")"

    jq \
        --arg k "$key" \
        --arg v "$value" \
        '.[$k] = $v' \
        "$file" > "$tmp"

    mv "$tmp" "$file"
}

# =====================================================================
# Set Raw JSON Object
# =====================================================================

json_set_raw() {

    local file="$1"
    local key="$2"
    local raw="$3"

    local tmp

    tmp="$(mktemp "${file}.XXXX")"

    jq \
        --arg k "$key" \
        --argjson r "$raw" \
        '.[$k] = $r' \
        "$file" > "$tmp"

    mv "$tmp" "$file"
}

# =====================================================================
# Finalize JSON
# =====================================================================

json_finalize() {

    local file="$1"

    local tmp

    tmp="$(mktemp "${file}.XXXX")"

    jq '.' "$file" > "$tmp"

    mv "$tmp" "$file"
}

# =====================================================================
# Validate JSON
# =====================================================================

json_validate() {

    local file="$1"

    jq . "$file" >/dev/null 2>&1
}

# =====================================================================
# File Exists
# =====================================================================

json_exists() {

    local file="$1"

    [[ -f "$file" ]]
}

# =====================================================================
# Get Field
# =====================================================================

json_get() {

    local file="$1"
    local query="$2"

    jq -r \
        "$query" \
        "$file" \
        2>/dev/null
}

# =====================================================================
# Get Field With Default
# =====================================================================

json_get_default() {

    local file="$1"
    local query="$2"
    local default="$3"

    jq -r \
        "$query // \"$default\"" \
        "$file" \
        2>/dev/null \
        || echo "$default"
}

# =====================================================================
# Stale File Detection
# =====================================================================

json_is_stale() {

    local file="$1"
    local max_age="$2"

    [[ -f "$file" ]] || return 0

    local now
    local modified

    now=$(date +%s)
    modified=$(stat -c %Y "$file")

    (( now - modified > max_age ))
}

# =====================================================================
# Required File
# =====================================================================

json_require() {

    local file="$1"

    [[ -f "$file" ]]
}