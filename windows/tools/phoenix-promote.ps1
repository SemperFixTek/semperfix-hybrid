<#
    phoenix-promote.ps1 (Unified Config Edition)
    Promotes SECONDARY to ACTIVE during failover.
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
$phoenix.Status.Role  = "SECONDARY-ACTIVE"
$phoenix.Status.State = "HEALTHY"
$phoenix.Status.Timestamp = $now.ToString("o")
$phoenix.Status.Message = "Failover: SECONDARY promoted to ACTIVE."

# Update lineage
$phoenix.Phoenix.Lineage = "SECONDARY"
$phoenix.Phoenix.LastUpdate = $now.ToString("o")

# Record action
$phoenix.Actions.LastAction = "Promote"
$phoenix.Actions.History += "[$($now.ToString("o"))] SECONDARY promoted to ACTIVE."

# Persist
$phoenix | ConvertTo-Json -Depth 8 | Set-Content -Path $PhoenixPath -Encoding UTF8

Write-Host "SECONDARY promoted to ACTIVE."
exit 0
