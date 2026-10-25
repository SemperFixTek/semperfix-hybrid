#!/usr/bin/env bash
# =====================================================================
# Phoenix Automation Suite — Metadata Fixer
# Version: Phoenix v2.1
# Component: phoenix-metadata-fixer
# Role: Maintenance / Controller-only
# Refactor: 2026-10-21 — Initial creation
# Maintainer: SemperFix Automation (Bruce)
# =====================================================================

set -euo pipefail

SFX_DIR="/opt/semperfix/scripts"
LOG="/opt/semperfix/logs/metadata-fixer.log"

echo "[FIXER] Phoenix Metadata Fixer — Phoenix v2.1" | tee "$LOG"
echo "[FIXER] Scanning directory: $SFX_DIR" | tee -a "$LOG"

fix_count=0

generate_metadata() {
    local file="$1"
    local base
    base=$(basename "$file")
    local id="${base%.sh}"

    cat <<EOF
# =====================================================================
# Phoenix Automation Suite — ${id//-/ }
# Version: Phoenix v2.1
# Component: $id
# Role: UNKNOWN (fix manually if needed)
# Refactor: $(date +%Y-%m-%d)
# Maintainer: SemperFix Automation (Bruce)
# =====================================================================

EOF
}

fix_file() {
    local file="$1"
    local base
    base=$(basename "$file")
    local id="${base%.sh}"

    echo "" | tee -a "$LOG"
    echo "[FIXER] Checking: $base" | tee -a "$LOG"

    local header
    header=$(head -n 20 "$file")

    local needs_fix="false"

    # Check required fields
    if ! grep -q "^# Phoenix Automation Suite" <<< "$header"; then needs_fix="true"; fi
    if ! grep -q "^# Version: Phoenix v2.1" <<< "$header"; then needs_fix="true"; fi
    if ! grep -q "^# Component:" <<< "$header"; then needs_fix="true"; fi
    if ! grep -q "^# Role:" <<< "$header"; then needs_fix="true"; fi
    if ! grep -q "^# Refactor:" <<< "$header"; then needs_fix="true"; fi
    if ! grep -q "^# Maintainer:" <<< "$header"; then needs_fix="true"; fi

    # Component-ID mismatch
    if grep -q "^# Component:" <<< "$header"; then
        local comp
        comp=$(grep "^# Component:" <<< "$header" | awk '{print $3}')
        if [[ "$comp" != "$id" ]]; then
            echo "[FIXER]   Component-ID mismatch: '$comp' → '$id'" | tee -a "$LOG"
            needs_fix="true"
        fi
    fi

    if [[ "$needs_fix" == "false" ]]; then
        echo "[FIXER]   PASS: Metadata OK" | tee -a "$LOG"
        return
    fi

    echo "[FIXER]   FIXING metadata…" | tee -a "$LOG"

    # Backup original
    cp "$file" "$file.bak"

    # Write new file with metadata block
    {
        generate_metadata "$file"
        tail -n +1 "$file" | sed '/^# Phoenix Automation Suite/,$d'
        tail -n +1 "$file"
    } > "${file}.tmp"

    mv "${file}.tmp" "$file"

    echo "[FIXER]   FIXED: $base" | tee -a "$LOG"
    fix_count=$((fix_count + 1))
}

for f in "$SFX_DIR"/*.sh; do
    fix_file "$f"
done

echo "" | tee -a "$LOG"
echo "[FIXER] Completed. Files fixed: $fix_count" | tee -a "$LOG"

exit 0
