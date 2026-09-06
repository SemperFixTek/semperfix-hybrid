<#
    phoenix-recover.ps1 (Unified Config Edition)
    MASTERZERO recovery → reclaim ACTIVE role.
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
$phoenix.Status.Role  = "MASTERZERO-ACTIVE"
$phoenix.Status.State = "HEALTHY"
$phoenix.Status.Timestamp = $now.ToString("o")
$phoenix.Status.Message = "MASTERZERO recovered and reclaimed ACTIVE role."

# Update lineage
$phoenix.Phoenix.Lineage = "MASTERZERO"
$phoenix.Phoenix.LastUpdate = $now.ToString("o")

# Record action
$phoenix.Actions.LastAction = "Recover"
$phoenix.Actions.History += "[$($now.ToString("o"))] MASTERZERO recovered and reclaimed ACTIVE."

# Persist
$phoenix | ConvertTo-Json -Depth 8 | Set-Content -Path $PhoenixPath -Encoding UTF8

Write-Host "MASTERZERO recovery complete."
exit 0
