<#
    phoenix-dryrun.ps1 (Unified Config Edition)
    Simulates MASTERZERO failure → SECONDARY promotion → MASTERZERO recovery.
#>

param(
    [string]$PhoenixPath = "C:\SemperFix\ConfigBackup\phoenix.json"
)

Write-Host "Phoenix v2 Dry-Run Starting..."

# 1. MASTERZERO failure
Write-Host "Simulating MASTERZERO failure..."
powershell -File "C:\SemperFix\Tools\phoenix-escalate.ps1" -Reason "Dry-run simulated failure"

Start-Sleep -Seconds 2

# 2. SECONDARY promotion
Write-Host "Simulating SECONDARY promotion..."
powershell -File "C:\SemperFix\Tools\phoenix-promote.ps1"

Start-Sleep -Seconds 2

# 3. MASTERZERO recovery
Write-Host "Simulating MASTERZERO recovery..."
powershell -File "C:\SemperFix\Tools\phoenix-recover.ps1"

Start-Sleep -Seconds 2

Write-Host "Dry-run complete."
exit 0
