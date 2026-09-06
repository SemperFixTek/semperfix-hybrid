<#
    Syncthing Health Module
    SemperFix Logging Format
    --------------------------------------
    Provides reusable health checks for Phoenix.
#>

# --- CONFIG ---
$LogPath = "C:\SemperFix\Logs\syncthing-health.log"
$ApiKey  = (Get-Content "C:\SemperFix\ConfigBackup\syncthing-apikey.txt")
$ApiUrl  = "http://127.0.0.1:8384"

# --- LOGGING ---
function Write-SFXLog {
    param([string]$Level, [string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[{0}] [{1}] {2}" -f $timestamp, $Level, $Message
    Write-Host $line
    Add-Content -Path $LogPath -Value $line
}

Write-SFXLog "INFO" "Syncthing health check starting."

# --- API CALL ---
try {
    $systemStatus = Invoke-RestMethod -Uri "$ApiUrl/rest/system/status" -Headers @{ "X-API-Key" = $ApiKey }
    Write-SFXLog "INFO" "Syncthing system status retrieved."
}
catch {
    Write-SFXLog "ERROR" "Failed to reach Syncthing API: $($_.Exception.Message)"
    return @{ Healthy = $false; Reason = "API unreachable" }
}

# --- FOLDER STATUS ---
try {
    $folderStatus = Invoke-RestMethod -Uri "$ApiUrl/rest/db/status?folder=MasterZero" -Headers @{ "X-API-Key" = $ApiKey }
    $configStatus = Invoke-RestMethod -Uri "$ApiUrl/rest/db/status?folder=ConfigBackup" -Headers @{ "X-API-Key" = $ApiKey }
    $assetsStatus = Invoke-RestMethod -Uri "$ApiUrl/rest/db/status?folder=Assets" -Headers @{ "X-API-Key" = $ApiKey }

    Write-SFXLog "INFO" "Syncthing folder statuses retrieved."
}
catch {
    Write-SFXLog "ERROR" "Failed to retrieve folder statuses: $($_.Exception.Message)"
    return @{ Healthy = $false; Reason = "Folder status error" }
}

function phoenix-syncthing-health {

    # --- HEALTH LOGIC ---
    $healthy =
        ($folderStatus.state -eq "idle") -and
        ($configStatus.state -eq "idle") -and
        ($assetsStatus.state -eq "idle")

    if ($healthy) {
        Write-SFXLog "INFO" "Syncthing health: GOOD (all folders idle)."
    }
    else {
        Write-SFXLog "WARN" "Syncthing health: DEGRADED (one or more folders not idle)."
    }

    # --- RETURN STRUCT ---
    return @{
        Healthy       = $healthy
        SystemStatus  = $systemStatus
        MasterZero    = $folderStatus
        ConfigBackup  = $configStatus
        Assets        = $assetsStatus
    }
}