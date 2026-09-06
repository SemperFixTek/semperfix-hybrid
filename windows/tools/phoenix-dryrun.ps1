<#
    Phoenix Dry-Run (Syncthing Transport)
    SemperFix Logging Format
#>

# --- CONFIG ---
$LogPath     = "C:\SemperFix\Logs\phoenix-dryrun.log"
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

Write-SFXLog "INFO" "Phoenix dry-run starting (Syncthing transport)."

# --- VERIFY SYNCTHING FOLDERS ---
foreach ($folder in @($MasterZeroPath, $ConfigBackupPath, $AssetsPath)) {
    if (-not (Test-Path $folder)) {
        Write-SFXLog "ERROR" "Missing Syncthing folder: $folder"
        exit 1
    }
    Write-SFXLog "INFO" "Verified Syncthing folder: $folder"
}

# --- VERIFY STATUS FILE ---
if (-not (Test-Path $StatusPath)) {
    Write-SFXLog "ERROR" "Phoenix status file missing at '$StatusPath'. Dry-run FAILED."
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

# --- DRY-RUN SUMMARY ---
Write-SFXLog "INFO" ("Phoenix Role: {0}" -f $statusJson.Role)
Write-SFXLog "INFO" ("Last Updated: {0}" -f $statusJson.LastUpdated)

Write-SFXLog "INFO" "Phoenix dry-run completed successfully (Syncthing transport)."
exit 0
