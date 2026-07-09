#!/usr/bin/env bash
set -e

# SemperFix WSL-safe ADS scrubber
# Runs Windows PowerShell to remove Zone.Identifier streams on NTFS

TARGET_PATH="${1:-C:\\SemperFix}"
RECURSE_FLAG="${2:--Recurse}"

echo "=== SemperFix WSL ADS Scrubber ==="
echo "Target (Windows path): $TARGET_PATH"
echo "Recurse: $RECURSE_FLAG"
echo

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "
param(
    [string]\$TargetPath = '$TARGET_PATH',
    [switch]\$Recurse
)

Write-Host '=== SemperFix Zone Identifier Purge (from WSL) ==='
Write-Host \"Target: \$TargetPath\"
Write-Host ''

if (-not (Test-Path \$TargetPath)) {
    Write-Host 'ERROR: Target path does not exist.'
    exit 1
}

\$files = Get-ChildItem -Path \$TargetPath -File -Recurse:\$Recurse -ErrorAction SilentlyContinue

\$removed = 0
\$checked = 0

foreachHere’s a **WSL-safe ADS scrubber** that you can run inside WSL, but it uses Windows’ PowerShell under the hood—so it actually removes `Zone.Identifier` streams correctly on NTFS.

Save this in WSL as:

`/opt/semperfix/scripts/wsl-ads-scrub.sh`

```bash
#!/usr/bin/env bash
set -e

# SemperFix WSL-safe ADS scrubber
# Runs Windows PowerShell to remove Zone.Identifier streams on NTFS

TARGET_PATH="${1:-C:\\SemperFix}"
RECURSE_FLAG="${2:--Recurse}"

echo "=== SemperFix WSL ADS Scrubber ==="
echo "Target (Windows path): $TARGET_PATH"
echo "Recurse: $RECURSE_FLAG"
echo

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "
param(
    [string]\$TargetPath = '$TARGET_PATH',
    [switch]\$Recurse
)

Write-Host '=== SemperFix Zone Identifier Purge (from WSL) ==='
Write-Host \"Target: \$TargetPath\"
Write-Host ''

if (-not (Test-Path \$TargetPath)) {
    Write-Host 'ERROR: Target path does not exist.'
    exit 1
}

\$files = Get-ChildItem -Path \$TargetPath -File -Recurse:\$Recurse -ErrorAction SilentlyContinue

\$removed = 0
\$checked = 0

foreachHere’s a **WSL-safe ADS scrubber** that you can run inside WSL, but it uses Windows’ PowerShell under the hood—so it actually removes `Zone.Identifier` streams correctly on NTFS.

Save this in WSL as:

`/opt/semperfix/scripts/wsl-ads-scrub.sh`

```bash
#!/usr/bin/env bash
set -e

# SemperFix WSL-safe ADS scrubber
# Runs Windows PowerShell to remove Zone.Identifier streams on NTFS

TARGET_PATH="${1:-C:\\SemperFix}"
RECURSE_FLAG="${2:--Recurse}"

echo "=== SemperFix WSL ADS Scrubber ==="
echo "Target (Windows path): $TARGET_PATH"
echo "Recurse: $RECURSE_FLAG"
echo

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "
param(
    [string]\$TargetPath = '$TARGET_PATH',
    [switch]\$Recurse
)

Write-Host '=== SemperFix Zone Identifier Purge (from WSL) ==='
Write-Host \"Target: \$TargetPath\"
Write-Host ''

if (-not (Test-Path \$TargetPath)) {
    Write-Host 'ERROR: Target path does not exist.'
    exit 1
}

\$files = Get-ChildItem -Path \$TargetPath -File -Recurse:\$Recurse -ErrorAction SilentlyContinue

\$removed = 0
\$checked = 0

foreach