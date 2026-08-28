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
# TRUST SYNCTHING'S SELF-SIGNED CERTIFICATE
# --------------------------------------------------------------------
add-type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;

public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(
        ServicePoint srvPoint, X509Certificate certificate,
        WebRequest request, int certificateProblem) {
        return true;
    }
}
"@

[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

# --------------------------------------------------------------------
# SYNCTHING PING (HTTPS + API KEY)
# --------------------------------------------------------------------
$pingUrl = "https://localhost:8384/rest/system/ping"
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

# --------------------------------------------------------------------
# PLACEHOLDER: Mesh / Node / Status calls
# --------------------------------------------------------------------
# Add GET-only endpoints here later (they will inherit HTTPS + cert bypass)

Write-Log "SemperFix Windows automation cycle complete."
Write-Log "=== SemperFix Windows Automation End ==="

exit 0
