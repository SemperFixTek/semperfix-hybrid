<#
    phoenix-role-check.ps1 (Unified Config Edition)
    Reports current Phoenix role/state from unified phoenix.json.
#>

param(
    [string]$PhoenixPath = "C:\SemperFix\ConfigBackup\phoenix.json"
)

if (-not (Test-Path $PhoenixPath)) {
    Write-Host "ERROR: phoenix.json missing at $PhoenixPath"
    exit 1
}

$phoenix = Get-Content -Raw -Path $PhoenixPath | ConvertFrom-Json

Write-Host "NodeRole: $($phoenix.NodeRole)"
Write-Host "Status.Role: $($phoenix.Status.Role)"
Write-Host "Status.State: $($phoenix.Status.State)"
Write-Host "Lineage: $($phoenix.Phoenix.Lineage)"
Write-Host "Syncthing Healthy: $($phoenix.Syncthing.Healthy)"
exit 0
