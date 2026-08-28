Param(
    [int]$TimeoutSec = 10
)

# Load config
$configPath = "C:\SemperFix\semperfix-config.json"
$config     = Get-Content $configPath -Raw | ConvertFrom-Json
$apiKey     = $config.Syncthing.ApiKey

# Logging setup
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

# --------------------------------------------------------------------
# TRUST SYNCTHING'S SELF-SIGNED CERTIFICATE (PowerShell 7+ compatible)
# --------------------------------------------------------------------
add-type @"
using System.Net.Http;
using System.Security.Cryptography.X509Certificates;

public static class SyncthingCertBypass {
    public static HttpClientHandler GetHandler() {
        var handler = new HttpClientHandler();
        handler.ServerCertificateCustomValidationCallback = 
            (message, cert, chain, errors) => true;
        return handler;
    }
}
"@

$handler = [SyncthingCertBypass]::GetHandler()
$client  = New-Object System.Net.Http.HttpClient($handler)

# --------------------------------------------------------------------
# SYNCTHING PING (HTTPS + API KEY)
# --------------------------------------------------------------------
$pingUrl = "https://127.0.0.1:8384/rest/system/ping"

try {
    Write-Log "Pinging Syncthing API at $pingUrl (TimeoutSec=$TimeoutSec)"

    $request = New-Object System.Net.Http.HttpRequestMessage "GET", $pingUrl
    $request.Headers.Add("X-API-Key", $apiKey)

    $response = $client.SendAsync($request).Result
    $content  = $response.Content.ReadAsStringAsync().Result

    if ($content -like '*"pong"*') {
        Write-Log "Syncthing API reachable (pong received)."
    } else {
        Write-Log "Syncthing API responded but content was unexpected: $content"
    }
}
catch {
    Write-Log "ERROR: Failed to reach Syncthing API: $($_.Exception.Message)"
}

Write-Log "SemperFix Windows automation cycle complete."
Write-Log "=== SemperFix Windows Automation End ==="

exit 0
