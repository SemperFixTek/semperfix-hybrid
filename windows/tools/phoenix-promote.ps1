<#
    Phoenix Promote (Syncthing Transport)
    SemperFix Logging Format
    --------------------------------------
    SECONDARY becomes ACTIVE using Syncthing-synced local folders.
#>

param(
    [string]$NodeRole = "SECONDARY"
)

# --- CONFIG ---
$LogPath     = "C:\SemperFix\Logs\phoenix-promote.log"
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

Write-SFXLog "INFO" "Phoenix promote starting (Syncthing transport). NodeRole=$NodeRole"

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
    Write-SFXLog "ERROR" "Phoenix status file missing at '$StatusPath'. Cannot promote."
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

# --- PROMOTION LOGIC ---
Write-SFXLog "INFO" "Promoting SECONDARY to ACTIVE."

try {
    Start-Service -Name "PhoenixService"
    Write-SFXLog "INFO" "Phoenix service started on SECONDARY."
}
catch {
    Write-SFXLog "ERROR" "Failed to start Phoenix service: $($_.Exception.Message)"
    exit 1
}

# --- UPDATE STATUS JSON ---
$promoteRecord = @{
    Role           = "SECONDARY-ACTIVE"
    PreviousRole   = $statusJson.Role
    PromotionSource = "MASTERZERO"
    Timestamp      = (Get-Date).ToString("o")
    Message        = "SECONDARY promoted to ACTIVE."
}

$promoteRecord | ConvertTo-Json -Depth 6 | Set-Content -Path $StatusPath

Write-SFXLog "INFO" "Phoenix status updated for SECONDARY-ACTIVE."
Write-SFXLog "INFO" "Phoenix promote completed successfully."
exit 0
