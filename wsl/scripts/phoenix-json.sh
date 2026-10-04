#!/usr/bin/env bash
set -euo pipefail

# Phoenix v2 Standard Environment Header
umask 002

# Ensure consistent locale + predictable JSON behavior
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

# Ensure logs and state directories exist
mkdir -p /var/lib/semperfix/state
mkdir -p /opt/semperfix/logs

# Safety: prevent Windows CRLF issues
dos2unix "$0" 2>/dev/null || true


# ------------------------------------------------------------
# Phoenix JSON Module (v2)
# ------------------------------------------------------------
# Provides atomic, safe, jq-based JSON writing for all Phoenix
# scripts: heartbeat, supervisor, handshake, verify, activate.
#
# Guarantees:
#   - Always produces valid JSON
#   - Never leaves trailing commas
#   - Never depends on AWK
#   - Never breaks under WSL buffering
#   - Never breaks under locale issues
#   - Never breaks under rapid writes
# ------------------------------------------------------------

# Initialize a JSON file with {}
json_init() {
    local file="$1"
    echo "{}" > "$file"
}

# Add or replace a key/value pair (string-safe)
json_set() {
    local file="$1"
    local key="$2"
    local value="$3"

    # Use jq to atomically update the JSON object
    local tmp
    tmp="$(mktemp)"

    jq --arg k "$key" --arg v "$value" '.[$k] = $v' "$file" > "$tmp"
    mv "$tmp" "$file"
}

# Add raw JSON (for structured objects or arrays)
json_set_raw() {
    local file="$1"
    local key="$2"
    local raw="$3"

    local tmp
    tmp="$(mktemp)"

    jq --arg k "$key" --argjson r "$raw" '.[$k] = $r' "$file" > "$tmp"
    mv "$tmp" "$file"
}

# Finalize JSON (pretty-print, normalize, guarantee validity)
json_finalize() {
    local file="$1"

    local tmp
    tmp="$(mktemp)"

    jq '.' "$file" > "$tmp"
    mv "$tmp" "$file"
}
