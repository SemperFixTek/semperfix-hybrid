#!/usr/bin/env bash
# =====================================================================
# Phoenix Automation Suite — Metadata Linter
# Version: Phoenix v2.1
# Component: phoenix-metadata-linter
# Role: Controller-only / Maintenance
# Refactor: 2026-10-21 — Initial creation
# Maintainer: SemperFix Automation (Bruce)
# =====================================================================

set -euo pipefail

SFX_DIR="/opt/semperfix/scripts"
LOG="/opt/semperfix/logs/metadata-linter.log"

echo "[LINTER] Phoenix Metadata Linter — Phoenix v2.1" | tee "$LOG"
echo "[LINTER] Scanning directory: $SFX_DIR" | tee -a "$LOG"

fail_count=0

lint_file() {
    local file="$1"
    local base
    base=$(basename "$file")
    local id="${base%.sh}"

    echo "" | tee -a "$LOG"
    echo "[LINTER] Checking: $base" | tee -a "$LOG"

    # Extract metadata block (first 20 lines)
    local header
    header=$(head -n 20 "$file")

    # Check presence of required fields
    local missing=()

    if ! grep -q "^# Phoenix Automation Suite" <<< "$header"; then
        missing+=("Component Name")
    fi

    if ! grep -q "^# Version: Phoenix v2.1" <<< "$header"; then
        missing+=("Version")
    fi

    if ! grep -q "^# Component:" <<< "$header"; then
        missing+=("Component")
    else
        # Validate component-id matches filename
        local comp
        comp=$(grep "^# Component:" <<< "$header" | awk '{print $3}')
        if [[ "$comp" != "$id" ]]; then
            echo "[LINTER]   ERROR: Component ID '$comp' does not match filename '$id'" | tee -a "$LOG"
            missing+=("Component-ID mismatch")
        fi
    fi

    if ! grep -q "^# Role:" <<< "$header"; then
        missing+=("Role")
    fi

    if ! grep -q "^# Refactor:" <<< "$header"; then
        missing+=("Refactor")
    else
        # Validate date format YYYY-MM-DD
        local date
        date=$(grep "^# Refactor:" <<< "$header" | awk '{print $3}')
        if ! [[ "$date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
            echo "[LINTER]   ERROR: Refactor date '$date' is not YYYY-MM-DD" | tee -a "$LOG"
            missing+=("Refactor-date invalid")
        fi
    fi

    if ! grep -q "^# Maintainer:" <<< "$header"; then
        missing+=("Maintainer")
    fi

    # Report results
    if (( ${#missing[@]} > 0 )); then
        echo "[LINTER]   FAIL: Missing or invalid metadata fields:" | tee -a "$LOG"
        for m in "${missing[@]}"; do
            echo "[LINTER]     - $m" | tee -a "$LOG"
        done
        fail_count=$((fail_count + 1))
    else
        echo "[LINTER]   PASS: Metadata valid" | tee -a "$LOG"
    fi
}

# Scan all SemperFix scripts
for f in "$SFX_DIR"/*.sh; do
    lint_file "$f"
done

echo "" | tee -a "$LOG"
echo "[LINTER] Completed. Failures: $fail_count" | tee -a "$LOG"

# Exit non-zero if failures found
if (( fail_count > 0 )); then
    exit 1
fi

exit 0
