<#
    Phoenix Handshake (Syncthing Transport)
    --------------------------------------
    Replaces SMB-based UNC access with local Syncthing-synced paths.

    Assumptions:
    - Syncthing keeps C:\SemperFix\ConfigBackup\ in sync between MASTERZERO and SECONDARY.
    - Phoenix writes its status file as: phoenix-status.json in ConfigBackup.
    - This script runs on MASTERZERO.
#>

param(
    [string]$LogPath = "C:\SemperFix\Logs\phoenix-handshake.log",
    [string]$StatusPath = "C:\SemperFix\ConfigBackup\phoenix-status.json"
)

function Write-Log {
    param(
        [string]$Level,
        [string]$Message
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[{0}] [{1}] {2}" -f $timestamp, $Level, $Message

    Write-Host $line
    Add-Content -Path $LogPath -Value $line
}

# --- Handshake start ---
Write-Log -Level "INFO" -Message "Phoenix handshake starting (Syncthing transport, SMB-free)."

# 1. Verify base SemperFix path
$basePath = "C:\SemperFix"
if (-not (Test-Path $basePath)) {
    Write-Log -Level "ERROR" -Message "Base path '$basePath' not found. Aborting handshake."
    exit 1
}

# 2. Verify ConfigBackup folder (Syncthing-synced)
$configBackupPath = "C:\SemperFix\ConfigBackup"
if (-not (Test-Path $configBackupPath)) {
    Write-Log -Level "ERROR" -Message "ConfigBackup folder '$configBackupPath' not found. Ensure Syncthing is running and folder is shared."
    exit 1
}

Write-Log -Level "INFO" -Message "ConfigBackup folder found at '$configBackupPath'."

# 3. Verify Phoenix status file (local, synced via Syncthing)
if (-not (Test-Path $StatusPath)) {
    Write-Log -Level "ERROR" -Message "Phoenix status file not found at '$StatusPath'. Handshake FAILED."
    exit 1
}

Write-Log -Level "INFO" -Message "Phoenix status file found at '$StatusPath'."

# 4. Load and validate status JSON
try {
    $statusJson = Get-Content -Path $StatusPath -Raw | ConvertFrom-Json
} catch {
    Write-Log -Level "ERROR" -Message "Failed to parse Phoenix status JSON at '$StatusPath': $($_.Exception.Message)"
    exit 1
}

# Optional: basic sanity checks on status content
if (-not $statusJson.Status) {
    Write-Log -Level "WARN" -Message "Phoenix status JSON missing 'Status' field. Proceeding, but status is ambiguous."
} else {
    Write-Log -Level "INFO" -Message ("Phoenix reported status: '{0}'" -f $statusJson.Status)
}

if ($statusJson.LastUpdated) {
    Write-Log -Level "INFO" -Message ("Phoenix status last updated: {0}" -f $statusJson.LastUpdated)
}

# 5. Handshake success (local Syncthing path validated)
Write-Log -Level "INFO" -Message "Phoenix handshake completed successfully using Syncthing-synced local path."
exit 0
