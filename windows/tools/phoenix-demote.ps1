<#
    Phoenix Demote (Syncthing Transport)
    SemperFix Logging Format
    --------------------------------------
    ACTIVE node steps down to PASSIVE.
#>

param(
    [string]$NodeRole = "SECONDARY-ACTIVE"
)

# --- CONFIG ---
$LogPath     = "C:\SemperFix\Logs\phoenix-demote.log"
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

Write-SFXLog "INFO" "Phoenix demote starting (Syncthing transport). NodeRole=$NodeRole"

# --- VERIFY SYNCTHING FOLDERS ---
foreach ($folder in @($MasterZeroPath, $ConfigBackupPath, $AssetsPath)) {
    if (-not (Test-Path $folder)) {
        Write-SFXLog "ERROR" "Required Syncthing folder missing: $folder"
        exit 1
    }
    Write-SFXLog "INFO" "Verified Syncthing folder: $folder"
}

# --- VERIFY STATUS FILE ---
if (-not (Test-Path $StatusPath)) {
    Write-SFXLog "ERROR" "Phoenix status file missing at '$StatusPath'. Cannot demote."
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

# --- DEMOTION LOGIC ---
Write-SFXLog "INFO" "Demoting ACTIVE node to PASSIVE."

try {
    Stop-Service -Name "PhoenixService"
    Write-SFXLog "INFO" "Phoenix service stopped."
}
catch {
    Write-SFXLog "WARN" "Phoenix service was not running or could not be stopped."
}

# --- UPDATE STATUS JSON ---
$demoteRecord = @{
    Role           = "SECONDARY-PASSIVE"
    PreviousRole   = $statusJson.Role
    DemotionSource = "ClusterController"
    Timestamp      = (Get-Date).ToString("o")
    Message        = "Node demoted to PASSIVE."
}

$demoteRecord | ConvertTo-Json -Depth 6 | Set-Content -Path $StatusPath

Write-SFXLog "INFO" "Phoenix status updated for SECONDARY-PASSIVE."
Write-SFXLog "INFO" "Phoenix demote completed successfully."
exit 0
