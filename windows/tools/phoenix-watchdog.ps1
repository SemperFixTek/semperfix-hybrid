<#
    Phoenix v2 Watchdog
    Unified Config Edition — uses phoenix.json as the single source of truth.
    Purpose:
        - Validate MASTERZERO integrity
        - Validate required paths/files/modules
        - Validate Syncthing health (optional)
        - Escalate to DEGRADED if critical checks fail
        - Prevent split-brain
#>

param(
    [string]$PhoenixJson = "C:\SemperFix\ConfigBackup\phoenix.json",
    [string]$StatusPath  = "C:\SemperFix\ConfigBackup\phoenix-status.json",
    [string]$LogPath     = "C:\SemperFix\Logs\phoenix-watchdog.log"
)

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$ts] [$Level] $Message"
    $line | Out-File -FilePath $LogPath -Append -Encoding UTF8
    Write-Host $line
}

# Load phoenix.json
try {
    $Phoenix = Get-Content $PhoenixJson | ConvertFrom-Json
    Write-Log "Loaded phoenix.json successfully."
}
catch {
    Write-Log "Failed to load phoenix.json: $($_.Exception.Message)" "ERROR"
    $EscReason = "Watchdog failure: phoenix.json unreadable."
    goto ESCALATE
}

# Extract watchdog config
if (-not $Phoenix.Watchdog) {
    Write-Log "phoenix.json missing Watchdog section." "ERROR"
    $EscReason = "Watchdog failure: Missing Watchdog section in phoenix.json."
    goto ESCALATE
}

$WD = $Phoenix.Watchdog

# Validate required paths
foreach ($path in $WD.RequiredPaths.Values) {
    if (-not (Test-Path $path)) {
        Write-Log "Missing required path: $path" "ERROR"
        $EscReason = "Missing required path: $path"
        goto ESCALATE
    }
}

# Validate required files
foreach ($file in $WD.RequiredFiles) {
    if (-not (Test-Path $file)) {
        Write-Log "Missing required file: $file" "ERROR"
        $EscReason = "Missing required file: $file"
        goto ESCALATE
    }
}

# Validate required folders
foreach ($folder in $WD.RequiredFolders) {
    if (-not (Test-Path $folder)) {
        Write-Log "Missing required folder: $folder" "ERROR"
        $EscReason = "Missing required folder: $folder"
        goto ESCALATE
    }
}

# Validate required modules
foreach ($module in $WD.RequiredModules) {
    $modulePath = "C:\SemperFix\Tools\$module"
    if (-not (Test-Path $modulePath)) {
        Write-Log "Missing required module: $modulePath" "ERROR"
        $EscReason = "Missing required module: $modulePath"
        goto ESCALATE
    }
}

# If we reach here, watchdog passes
Write-Log "Watchdog health OK — no escalation required."
return

# Escalation block
:ESCALATE

Write-Log "Watchdog escalation triggered: $EscReason" "ERROR"

# Load current phoenix-status.json
try {
    $Status = Get-Content $StatusPath | ConvertFrom-Json
}
catch {
    Write-Log "phoenix-status.json unreadable during escalation." "ERROR"
    # Create minimal status doc
    $Status = @{
        Role = "MASTERZERO"
        Status = "DEGRADED"
    }
}

# Update status
$Status.Status = "DEGRADED"
$Status.Role   = "SECONDARY-ACTIVE"   # Hand control to SECONDARY
$Status.EscalationReason = $EscReason
$Status.Timestamp = (Get-Date).ToString("o")
$Status.Message = "Phoenix escalation executed."

# Write updated status
$Status | ConvertTo-Json -Depth 8 | Set-Content -Path $StatusPath -Encoding UTF8

Write-Log "phoenix-status.json updated — MASTERZERO marked DEGRADED and SECONDARY promoted."
return
