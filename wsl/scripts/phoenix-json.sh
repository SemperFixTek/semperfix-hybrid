#!/usr/bin/env bash
set -euo pipefail

# Phoenix v2 JSON Writer Module
# Atomic, safe, jq‑based JSON writing for:
#   heartbeat, supervisor, handshake, verify, activate

# Safety: prevent Windows CRLF issues
dos2unix "$0" 2>/dev/null || true

# ------------------------------------------------------------
# JSON Initialization
# ------------------------------------------------------------
json_init() {
    local file="$1"
    echo "{}" > "$file"
}

# ------------------------------------------------------------
# Set a string value (atomic)
# ------------------------------------------------------------
json_set() {
    local file="$1"
    local key="$2"
    local value="$3"

    # mktemp inside the same directory ensures correct ownership
    local tmp
    tmp="$(mktemp "${file}.XXXX")"

    jq --arg k "$key" --arg v "$value" '.[$k] = $v' "$file" > "$tmp"
    mv "$tmp" "$file"
}

# ------------------------------------------------------------
# Set a raw JSON value (arrays, objects)
# ------------------------------------------------------------
json_set_raw() {
    local file="$1"
    local key="$2"
    local raw="$3"

    local tmp
    tmp="$(mktemp "${file}.XXXX")"

    jq --arg k "$key" --argjson r "$raw" '.[$k] = $r' "$file" > "$tmp"
    mv "$tmp" "$file"
}

# ------------------------------------------------------------
# Finalize JSON (normalize, pretty‑print)
# ------------------------------------------------------------
json_finalize() {
    local file="$1"

    local tmp
    tmp="$(mktemp "${file}.XXXX")"

    jq '.' "$file" > "$tmp"
    mv "$tmp" "$file"
}
