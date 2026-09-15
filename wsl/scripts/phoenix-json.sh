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

# ---------- Close JSON (remove trailing comma) ----------
json_close() {
    local file="$1"

    # Remove trailing comma from last entry
    sed -i '$ s/,$//' "$file"

    # Close JSON object
    echo "}" >> "$file"
}

# ---------- Utility: Write raw JSON blocks ----------
json_add_raw() {
    local file="$1"
    local key="$2"
    local raw="$3"

    echo "  \"${key}\": ${raw}," >> "$file"
}

# ---------- Utility: Write arrays ----------
json_add_array() {
    local file="$1"
    local key="$2"
    shift 2

    echo "  \"${key}\": [" >> "$file"

    for item in "$@"; do
        item=$(printf '%s' "$item" | jq -Rsa .)
        item="${item:1:${#item}-2}"
        echo "    \"${item}\"," >> "$file"
    done

    # Remove trailing comma
    sed -i '$ s/,$//' "$file"

    echo "  ]," >> "$file"
}

# ---------- Utility: Write nested objects ----------
json_add_object_start() {
    local file="$1"
    local key="$2"
    echo "  \"${key}\": {" >> "$file"
}

json_add_object_end() {
    local file="$1"
    sed -i '$ s/,$//' "$file"
    echo "  }," >> "$file"
}
