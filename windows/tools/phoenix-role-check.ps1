<#
    Phoenix Role Check (Syncthing Transport)
    SemperFix Logging Format
#>

# --- CONFIG ---
$LogPath     = "C:\SemperFix\Logs\phoenix-role-check.log"
$StatusPath  = "C:\SemperFix\ConfigBackup\phoenix-status.json"

# --- LOGGING ---
function Write-SFXLog {
    param([string]$Level, [string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[{0}] [{1}] {2}" -f $timestamp, $Level, $Message
    Write-Host $line
    Add-Content -Path $LogPath -Value $line
}

Write-SFXLog "INFO" "Phoenix role-check starting (Syncthing transport)."

# --- VERIFY STATUS FILE ---
if (-not (Test-Path $StatusPath)) {
    Write-SFXLog "ERROR" "Phoenix status file missing at '$StatusPath'. Cannot determine role."
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

# --- OUTPUT ROLE ---
Write-SFXLog "INFO" ("Current Phoenix Role: {0}" -f $statusJson.Role)

$statusJson.Role
exit 0
