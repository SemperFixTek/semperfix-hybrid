<#
    Phoenix Escalate (Syncthing Transport)
    SemperFix Logging Format
#>

param(
    [string]$Reason = "Unknown"
)

# --- CONFIG ---
$LogPath     = "C:\SemperFix\Logs\phoenix-escalate.log"
$StatusPath  = "C:\SemperFix\ConfigBackup\phoenix-status.json"

# --- LOGGING ---
function Write-SFXLog {
    param([string]$Level, [string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[{0}] [{1}] {2}" -f $timestamp, $Level, $Message
    Write-Host $line
    Add-Content -Path $LogPath -Value $line
}

Write-SFXLog "INFO" "Phoenix escalation starting (Syncthing transport)."
Write-SFXLog "INFO" "Reason: $Reason"

# --- VERIFY STATUS FILE ---
if (-not (Test-Path $StatusPath)) {
    Write-SFXLog "ERROR" "Phoenix status file missing at '$StatusPath'. Cannot escalate."
    exit 1
}

Write-SFXLog "INFO" "Phoenix status file found. Parsing..."

try {
    $statusJson = Get-Content -Path $StatusPath -Raw | ConvertFrom-Json
    Write-SFXLog "INFO" "Phoenix status JSON parsed successfully."
}
catch {
    Write-SFXLog "ERROR" "Phoenix status JSON parse error: $($_.Exception.Message)"
    exit 1
}

# --- ESCALATION ACTION ---
Write-SFXLog "WARN" "Escalation triggered. Marking Phoenix status as DEGRADED."

$escalateRecord = @{
    Role           = $statusJson.Role
    Status         = "DEGRADED"
    EscalationReason = $Reason
    Timestamp      = (Get-Date).ToString("o")
    Message        = "Phoenix escalation executed."
}

$escalateRecord | ConvertTo-Json -Depth 6 | Set-Content -Path $StatusPath

Write-SFXLog "INFO" "Phoenix status updated to DEGRADED."
Write-SFXLog "INFO" "Phoenix escalation completed."
exit 0
