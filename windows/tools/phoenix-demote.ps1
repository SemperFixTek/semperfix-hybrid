<#
    phoenix-demote.ps1 (Unified Config Edition)
    Demotes SECONDARY from ACTIVE → PASSIVE after MASTERZERO recovery.
#>

param(
    [string]$PhoenixPath = "C:\SemperFix\ConfigBackup\phoenix.json"
)

if (-not (Test-Path $PhoenixPath)) {
    Write-Host "ERROR: phoenix.json missing at $PhoenixPath"
    exit 1
}

$phoenix = Get-Content -Raw -Path $PhoenixPath | ConvertFrom-Json
$now = Get-Date

# Update status
$phoenix.Status.Role  = "SECONDARY-PASSIVE"
$phoenix.Status.State = "HEALTHY"
$phoenix.Status.Timestamp = $now.ToString("o")
$phoenix.Status.Message = "Recovery: SECONDARY demoted to PASSIVE."

# Record action
$phoenix.Actions.LastAction = "Demote"
$phoenix.Actions.History += "[$($now.ToString("o"))] SECONDARY demoted to PASSIVE."

# Persist
$phoenix | ConvertTo-Json -Depth 8 | Set-Content -Path $PhoenixPath -Encoding UTF8

Write-Host "SECONDARY demoted to PASSIVE."
exit 0
