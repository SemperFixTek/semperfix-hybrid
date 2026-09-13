<#
    Phoenix Failover (Syncthing Transport)
    SemperFix Logging Format
    --------------------------------------
    SECONDARY becomes ACTIVE using Syncthing-synced local folders.
#>

# --- CONFIG ---
$LogPath     = "C:\SemperFix\Logs\phoenix-failover.log"
$StatusPath  = "C:\SemperFix\ConfigBackup\phoenix-status.json"
$MasterZeroPath = "C:\SemperFix\MasterZero"
$ConfigBackupPath = "C:\SemperFix\ConfigBackup"
$AssetsPath = "C:\SemperFix\Assets"

# --- LOGGING ---
function Write-SFXLog {
    param([string]$Level, [string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[{0}] [{1}] {2}" -f $timestamp, $Level, $Message
    Write-Host $line
    Add-Content -Path $LogPath -Value $line
}

Write-SFXLog "INFO" "Phoenix failover starting (Syncthing transport, SMB-free)."

# --- VERIFY SYNCTHING FOLDERS ---
foreach ($folder in @($MasterZeroPath, $ConfigBackupPath, $AssetsPath)) {
    if (-not (Test-Path $folder)) {
        Write-SFXLog "ERROR" "Required Syncthing folder missing: $folder"
        exit 1
    }
    Write-SFXLog "INFO" "Verified Syncthing folder: $folder"
}

# --- VERIFY PHOENIX STATUS FILE ---
if (-not (Test-Path $StatusPath)) {
    Write-SFXLog "ERROR" "Phoenix status file missing at '$StatusPath'. Cannot failover."
    exit 1
}

Write-SFXLog "INFO" "Phoenix status file found at '$StatusPath'. Parsing..."

try {
    $statusJson = Get-Content -Path $StatusPath -Raw | ConvertFrom-Json
    Write-SFXLog "INFO" "Phoenix status JSON parsed successfully."
}
catch {
    Write-SFXLog "ERROR" "Phoenix status JSON parse error: $($_.Exception.Message)"
    exit 1
}

# --- VALIDATE STATUS CONTENT ---
if ($statusJson.Status -ne "DEGRADED" -and $statusJson.Status -ne "FAILOVER_ALLOWED") {
    Write-SFXLog "WARN" "Phoenix status does not explicitly allow failover. Proceeding with caution."
} else {
    Write-SFXLog "INFO" "Phoenix status indicates failover is allowed."
}

# --- PROMOTE SECONDARY ---
Write-SFXLog "INFO" "Promoting SECONDARY to ACTIVE Phoenix node."

# Example: start Phoenix service (replace with your actual service name)
try {
    Start-Service -Name "PhoenixService"
    Write-SFXLog "INFO" "Phoenix service started on SECONDARY."
}
catch {
    Write-SFXLog "ERROR" "Failed to start Phoenix service: $($_.Exception.Message)"
    exit 1
}

# --- UPDATE STATUS JSON LOCALLY ---
$failoverRecord = @{
    Role          = "SECONDARY-ACTIVE"
    PreviousRole  = "SECONDARY-PASSIVE"
    FailoverSource = "MASTERZERO"
    Timestamp     = (Get-Date).ToString("o")
}

$failoverRecord | ConvertTo-Json -Depth 5 | Set-Content -Path $StatusPath

Write-SFXLog "INFO" "Phoenix status updated for SECONDARY-ACTIVE."

# --- COMPLETE ---
Write-SFXLog "INFO" "Phoenix failover completed successfully using Syncthing transport."
exit 0
