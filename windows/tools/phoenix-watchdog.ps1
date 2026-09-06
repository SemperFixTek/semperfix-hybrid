<#
    phoenix-watchdog.ps1 (Unified Config Edition)
    Validates system integrity + Syncthing health.
    Escalates MASTERZERO → DEGRADED when required.
#>

param(
    [string]$PhoenixPath = "C:\SemperFix\ConfigBackup\phoenix.json",
    [string]$LogPath = "C:\SemperFix\Logs\phoenix-watchdog.log"
)

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$ts] [$Level] $Message"
    $line | Out-File -FilePath $LogPath -Append -Encoding UTF8
    Write-Host $line
}

# Load phoenix.json
if (-not (Test-Path $PhoenixPath)) {
    Write-Log "phoenix.json missing at $PhoenixPath" "ERROR"
    exit 1
}

$phoenix = Get-Content -Raw -Path $PhoenixPath | ConvertFrom-Json
Write-Log "Loaded phoenix.json successfully."

# Load syncthing health function
. "C:\SemperFix\Tools\phoenix-syncthing-health.ps1"

# Evaluate Syncthing health
$health = phoenix-syncthing-health -PhoenixPathInner $PhoenixPath

if (-not $health.Healthy) {
    Write-Log "Watchdog: Syncthing health degraded: $($health.Reason)" "WARN"

    # Escalate MASTERZERO → DEGRADED
    Write-Log "Watchdog: Escalating MASTERZERO → DEGRADED."
    powershell -File "C:\SemperFix\Tools\phoenix-escalate.ps1" -Reason $health.Reason

    exit 0
}

Write-Log "Syncthing health OK."

# Validate required paths/files/modules/folders
$wd = $phoenix.Watchdog

foreach ($path in $wd.RequiredPaths.GetEnumerator()) {
    if (-not (Test-Path $path.Value)) {
        Write-Log "Missing required path: $($path.Value)" "ERROR"
        powershell -File "C:\SemperFix\Tools\phoenix-escalate.ps1" -Reason "Missing required path: $($path.Value)"
        exit 0
    }
}

foreach ($file in $wd.RequiredFiles) {
    if (-not (Test-Path $file)) {
        Write-Log "Missing required file: $file" "ERROR"
        powershell -File "C:\SemperFix\Tools\phoenix-escalate.ps1" -Reason "Missing required file: $file"
        exit 0
    }
}

foreach ($folder in $wd.RequiredFolders) {
    if (-not (Test-Path $folder)) {
        Write-Log "Missing required folder: $folder" "ERROR"
        powershell -File "C:\SemperFix\Tools\phoenix-escalate.ps1" -Reason "Missing required folder: $folder"
        exit 0
    }
}

Write-Log "Watchdog: All checks passed. No escalation required."
exit 0
