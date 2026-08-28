Param(
    [int]$TimeoutSec = 10
)

# Load config
$configPath = "C:\SemperFix\semperfix-config.json"
$config     = Get-Content $configPath -Raw | ConvertFrom-Json
$apiKey     = $config.Syncthing.ApiKey
#
$LogPath = "C:\SemperFix\Logs\automation.log"
if (!(Test-Path (Split-Path $LogPath))) {
    New-Item -ItemType Directory -Path (Split-Path $LogPath) -Force | Out-Null
}

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp [SemperFix-Automation] $Message" | Tee-Object -FilePath $LogPath -Append
}

Write-Log "=== SemperFix Windows Automation Start ==="

# --- Syncthing ping (no CSRF, no auth) ---
$pingUrl = "http://localhost:8384/rest/system/ping"

$headers = @{ "X-API-Key" = $apiKey }

try {
    Write-Log "Pinging Syncthing API at $pingUrl (TimeoutSec=$TimeoutSec)"
    $response = Invoke-WebRequest -Uri $pingUrl -Headers $headers -UseBasicParsing -TimeoutSec $TimeoutSec

    if ($response.Content -like '*"pong"*') {
        Write-Log "Syncthing API reachable (pong received)."
    } else {
        Write-Log "Syncthing API responded but content was unexpected: $($response.Content)"
    }
}
catch {
    Write-Log "ERROR: Failed to reach Syncthing API: $($_.Exception.Message)"
}

# --- Placeholder: mesh / node / status calls that do NOT require CSRF ---
# You can safely add more GET-only endpoints here later if needed.

Write-Log "SemperFix Windows automation cycle complete."
Write-Log "=== SemperFix Windows Automation End ==="

exit 0