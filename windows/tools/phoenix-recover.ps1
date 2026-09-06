<#
    Phoenix Recovery (Syncthing Transport)
    SemperFix Logging Format
    --------------------------------------
    MASTERZERO returns online and reclaims authoritative role.
#>

param(
    [string]$NodeRole = "MASTERZERO"
)

# --- CONFIG ---
$LogPath     = "C:\SemperFix\Logs\phoenix-recover.log"
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

Write-SFXLog "INFO" "Phoenix recovery starting (Syncthing transport, SMB-free)."
Write-SFXLog "INFO" "NodeRole parameter: $NodeRole"

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
    Write-SFXLog "ERROR" "Phoenix status file missing at '$StatusPath'. Cannot recover."
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

# --- VALIDATE CURRENT ROLE ---
if ($statusJson.Role -ne "SECONDARY-ACTIVE") {
    Write-SFXLog "WARN" "Phoenix status does not indicate SECONDARY-ACTIVE. Recovery may not be required."
} else {
    Write-SFXLog "INFO" "Detected SECONDARY-ACTIVE state. MASTERZERO recovery appropriate."
}

# --- RECOVERY ACTIONS ---
Write-SFXLog "INFO" "Beginning MASTERZERO recovery actions."

# Example: restart Phoenix service on MASTERZERO
try {
    Restart-Service -Name "PhoenixService"
    Write-SFXLog "INFO" "Phoenix service restarted on MASTERZERO."
}
catch {
    Write-SFXLog "ERROR" "Failed to restart Phoenix service: $($_.Exception.Message)"
    exit 1
}

# --- UPDATE STATUS JSON ---
$recoveryRecord = @{
    Role           = "MASTERZERO-ACTIVE"
    PreviousRole   = $statusJson.Role
    RecoverySource = "SECONDARY"
    Timestamp      = (Get-Date).ToString("o")
    Message        = "MASTERZERO recovered and restored as authoritative node."
}

$recoveryRecord | ConvertTo-Json -Depth 6 | Set-Content -Path $StatusPath

Write-SFXLog "INFO" "Phoenix status updated for MASTERZERO-ACTIVE."

# --- COMPLETE ---
Write-SFXLog "INFO" "Phoenix recovery completed successfully using Syncthing transport."
exit 0
