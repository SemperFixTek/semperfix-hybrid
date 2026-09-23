#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Phoenix JSON Writer (v2)
# Safe JSON output utilities for all Phoenix WSL modules
# ============================================================

# ---------- Initialize a JSON file ----------
json_init() {
    local file="$1"
    echo "{" > "$file"
}

# ---------- Add a key/value pair safely ----------
json_add() {
    local file="$1"
    local key="$2"
    local value="$3"

    # Escape value safely using jq
    value=$(printf '%s' "$value" | jq -Rsa .)
    value="${value:1:${#value}-2}"

    echo "  \"${key}\": \"${value}\"," >> "$file"
}

# ---------- Add raw JSON (for peer_dump) ----------
json_add_raw() {
    local file="$1"
    local key="$2"
    local raw="$3"

    echo "  \"${key}\": ${raw}," >> "$file"
}

# ---------- Close JSON (remove trailing comma) ----------
json_close() {
    local file="$1"

    # Remove trailing comma from last entry
    sed -i '$ s/,$//' "$file"

    # Close JSON object
    echo "}" >> "$file"
}
