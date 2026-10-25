#!/usr/bin/env bash
set -euo pipefail

SFX_DIR="/opt/semperfix/scripts"

echo "=== SemperFix Script Integrity Checker ==="
echo "Scanning: $SFX_DIR"
echo

fail() { echo "[FAIL] $1"; }
pass() { echo "[PASS] $1"; }

for f in "$SFX_DIR"/*.sh; do
    echo "Checking: $(basename "$f")"

    # 1. File exists
    [[ -f "$f" ]] || { fail "Missing file"; continue; }

    # 2. Execute bit
    if [[ ! -x "$f" ]]; then
        fail "Missing execute bit"
    else
        pass "Execute bit OK"
    fi

    # 3. Directory execute bit
    if [[ ! -x "$SFX_DIR" ]]; then
        fail "Directory missing execute bit"
    else
        pass "Directory execute bit OK"
    fi

    # 4. Ownership
    owner=$(stat -c %U "$f")
    group=$(stat -c %G "$f")
    if [[ "$owner" != "root" || "$group" != "semperfix" ]]; then
        fail "Wrong ownership ($owner:$group)"
    else
        pass "Ownership OK (root:semperfix)"
    fi

    # 5. Permissions
    perms=$(stat -c %a "$f")
    if [[ "$perms" != "775" && "$perms" != "755" ]]; then
        fail "Unexpected permissions ($perms)"
    else
        pass "Permissions OK ($perms)"
    fi

    # 6. Shebang correctness
    read -r firstline < "$f"
    if [[ "$firstline" != "#!/usr/bin/env bash" ]]; then
        fail "Incorrect shebang"
    else
        pass "Shebang OK"
    fi

    # 7. CRLF detection
    if grep -q $'\r' "$f"; then
        fail "CRLF detected"
    else
        pass "No CRLF"
    fi

    # 8. UMask correctness
    if grep -q "^UMask" "$f"; then
        fail "UMask found in script (should be lowercase 'umask')"
    fi

    if grep -q "^umask 002" "$f"; then
        pass "umask OK"
    else
        fail "umask missing or incorrect"
    fi

    # 9. Truncated or binary garbage detection
    if ! grep -q "phoenix" "$f"; then
        fail "File may be truncated or missing expected content"
    else
        pass "Content sanity OK"
    fi

    echo
done

echo "=== Integrity Check Complete ==="
