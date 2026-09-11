<#
    phoenix-syncthing-health.ps1 (Unified Config + Diagnostic Edition)
    - Provides phoenix-syncthing-health for supervisor/watchdog compatibility.
    - Logs detailed diagnostics: node role, node name, API URL, API key (masked), HTTP status, and response body on error.
    - Writes Syncthing health + Phoenix.LastUpdate back into phoenix.json.
#>

param(
    [string]$PhoenixPath = "C:\SemperFix\ConfigBackup\phoenix.json",
    [string]$LogPath     = "C:\SemperFix\Logs\syncthing-health.log"
)

function Write-HealthLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )

    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[{0}] [{1}] {2}" -f $ts, $Level, $Message
    Add-Content -Path $LogPath -Value $line -Encoding UTF8
}

function phoenix-syncthing-health {
    param(
        [string]$PhoenixPathInner = "C:\SemperFix\ConfigBackup\phoenix.json",
        [string]$LogPathInner     = "C:\SemperFix\Logs\syncthing-health.log"
    )

    Write-HealthLog -Message "Syncthing health check starting. PhoenixPathInner=$PhoenixPathInner" -Level "INFO"

    if (-not (Test-Path $PhoenixPathInner)) {
        Write-HealthLog -Message "phoenix.json missing at $PhoenixPathInner" -Level "ERROR"
        return @{
            Healthy = $false
            Reason  = "phoenix.json missing"
            Status  = $null
        }
    }

    $phoenix = Get-Content -Raw -Path $PhoenixPathInner | ConvertFrom-Json

    # Determine local node based on NodeRole
    $localNode = $phoenix.Nodes | Where-Object { $_.Name -eq $phoenix.NodeRole }

    if (-not $localNode) {
        Write-HealthLog -Message "Local node not found in phoenix.json. NodeRole=$($phoenix.NodeRole)" -Level "ERROR"
        return @{
            Healthy = $false
            Reason  = "Local node not found in phoenix.json"
            Status  = $null
        }
    }

    $apiUrl = $localNode.ApiUrl
    $apiKey = $localNode.ApiKey

    # Mask API key for logging
    $apiKeyMasked = if ($apiKey -and $apiKey.Length -ge 8) {
        $apiKey.Substring(0,4) + ("*" * ($apiKey.Length - 8)) + $apiKey.Substring($apiKey.Length - 4)
    } elseif ($apiKey) {
        ("*" * $apiKey.Length)
    } else {
        "<null>"
    }

    Write-HealthLog -Message ("Using NodeName={0} NodeRole={1} ApiUrl={2} ApiKeyMasked={3}" -f $localNode.Name, $phoenix.NodeRole, $apiUrl, $apiKeyMasked) -Level "INFO"

    $uri = "$apiUrl/rest/system/status"
    Write-HealthLog -Message "Attempting GET $uri" -Level "INFO"

    try {
        $resp = Invoke-RestMethod -Uri $uri -Headers @{ "X-API-Key" = $apiKey }

        Write-HealthLog -Message "Syncthing system status retrieved successfully." -Level "INFO"

        return @{
            Healthy = $true
            Reason  = "OK"
            Status  = $resp
        }
    }
    catch {
        $ex = $_.Exception
        $httpStatusCode = $null
        $responseBody   = $null

        if ($ex -is [System.Net.Http.HttpRequestException] -and $ex.Response) {
            try {
                $httpStatusCode = $ex.Response.StatusCode
                $responseBody   = $ex.Response.ToString()
            } catch {
                $responseBody = "<unable to read response body>"
            }
        }

        Write-HealthLog -Message ("ERROR Failed to reach Syncthing API: {0}" -f $ex.Message) -Level "ERROR"

        if ($httpStatusCode) {
            Write-HealthLog -Message ("HTTP StatusCode: {0}" -f $httpStatusCode) -Level "ERROR"
        }

        if ($responseBody) {
            Write-HealthLog -Message ("Response body: {0}" -f $responseBody) -Level "ERROR"
        }

        return @{
            Healthy = $false
            Reason  = $ex.Message
            Status  = $null
        }
    }
}

# If script is run directly, update phoenix.json
$health = phoenix-syncthing-health -PhoenixPathInner $PhoenixPath -LogPathInner $LogPath

if (-not (Test-Path $PhoenixPath)) {
    Write-HealthLog -Message "phoenix.json missing at $PhoenixPath during direct run; cannot write health." -Level "ERROR"
    Write-Host "phoenix.json missing; Syncthing health not written."
    return
}

$phoenix = Get-Content -Raw -Path $PhoenixPath | ConvertFrom-Json
$now = Get-Date

$phoenix.Syncthing = $health
$phoenix.Phoenix.LastUpdate = $now.ToString("o")

$phoenix | ConvertTo-Json -Depth 8 | Set-Content -Path $PhoenixPath -Encoding UTF8

Write-HealthLog -Message ("Syncthing health written to {0} Healthy={1} Reason={2}" -f $PhoenixPath, $health.Healthy, $health.Reason) -Level "INFO"
Write-Host "Syncthing health updated."
