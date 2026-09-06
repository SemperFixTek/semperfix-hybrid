<#
    phoenix-escalate.ps1 (Unified Config Edition)
    Escalates MASTERZERO → DEGRADED and hands control to SECONDARY.
#>

param(
    [string]$PhoenixPath = "C:\SemperFix\ConfigBackup\phoenix.json",
    [string]$Reason = "Unknown escalation"
)

if (-not (Test-Path $PhoenixPath)) {
    Write-Host "ERROR: phoenix.json missing at $PhoenixPath"
    exit 1
}

$phoenix = Get-Content -Raw -Path $PhoenixPath | ConvertFrom-Json
$now = Get-Date

# Update status
$phoenix.Status.Role  = "SECONDARY-ACTIVE"
$phoenix.Status.State = "DEGRADED"
$phoenix.Status.EscalationReason = $Reason
$phoenix.Status.Timestamp = $now.ToString("o")
$phoenix.Status.Message = "Watchdog escalation executed."

# Record action
$phoenix.Actions.LastAction = "Escalate"
$phoenix.Actions.History += "[$($now.ToString("o"))] Escalation: $Reason"

# Persist
$phoenix | ConvertTo-Json -Depth 8 | Set-Content -Path $PhoenixPath -Encoding UTF8

Write-Host "MASTERZERO escalated → DEGRADED."
exit 0
