<#
<<<<<<< HEAD
    phoenix-syncthing-health.ps1
    Drop-in replacement with robust ConfigBackup discovery, diagnostics, localhost fallback, and pwsh-friendly behavior.

    Usage:
      pwsh -NoProfile -ExecutionPolicy Bypass -File .\phoenix-syncthing-health.ps1
      pwsh -NoProfile -ExecutionPolicy Bypass -File .\phoenix-syncthing-health.ps1 -RevealApiKey

    Behavior:
      - Locates the nearest ConfigBackup/phoenix.json by walking up from the script folder.
      - Falls back to C:\SemperFix\ConfigBackup\phoenix.json if discovery fails.
      - Writes diagnostics to C:\SemperFix\Logs\syncthing-health.log (creates directory if missing).
      - Masks API keys in logs by default; use -RevealApiKey only temporarily on a secure terminal.
      - Avoids calling 127.0.0.1 for remote nodes; attempts hostname/IP matching and safe fallbacks.
#>

param(
    [string]$PhoenixPath = $null,
    [switch]$RevealApiKey
)

# --- Resolve PhoenixPath (Option B: robust discovery) -----------------------
if (-not $PhoenixPath) {
    $current = $PSScriptRoot
    $found = $null

    while ($current -and ($current -ne [System.IO.Path]::GetPathRoot($current))) {
        $candidate = Join-Path $current "ConfigBackup"
        if (Test-Path $candidate) {
            $found = Join-Path $candidate "phoenix.json"
            break
=======
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
>>>>>>> 9f05a1b271981a50456b118fd05def3dd96a74f5
        }
        $current = Split-Path $current -Parent
    }

<<<<<<< HEAD
    if ($found) {
        $PhoenixPath = $found
    } else {
        # Final canonical fallback
        $PhoenixPath = "C:\SemperFix\ConfigBackup\phoenix.json"
    }
}

# --- Logging helpers --------------------------------------------------------
$LogDir = "C:\SemperFix\Logs"
if (-not (Test-Path $LogDir)) { New-Item -Path $LogDir -ItemType Directory -Force | Out-Null }
$LogFile = Join-Path $LogDir "syncthing-health.log"
=======
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
>>>>>>> 9f05a1b271981a50456b118fd05def3dd96a74f5

function Write-Diag {
    param([string]$Text)
    $ts = (Get-Date).ToString("o")
    $line = "[$ts] $Text"
    try { Add-Content -Path $LogFile -Value $line -Encoding UTF8 } catch { Write-Host $line }
}

function Mask-Key {
    param([string]$key)
    if (-not $key) { return "<empty>" }
    if ($key.Length -le 8) { return ("*" * ([Math]::Max(0, $key.Length - 4))) + $key.Substring([Math]::Max(0, $key.Length - 4)) }
    $prefix = $key.Substring(0,4)
    $suffix = $key.Substring($key.Length - 4)
    $maskLen = [Math]::Max(0, $key.Length - 8)
    return "$prefix" + ("*" * $maskLen) + "$suffix"
}

# --- Core health function --------------------------------------------------
function phoenix-syncthing-health {
    param(
        [string]$PhoenixPathInner = $PhoenixPath
    )

    Write-Diag "Syncthing health check starting. PhoenixPathInner=$PhoenixPathInner"

    if (-not (Test-Path $PhoenixPathInner)) {
        Write-Diag "ERROR phoenix.json missing at $PhoenixPathInner"
        return @{ Healthy = $false; Reason = "phoenix.json missing"; Status = $null }
    }

    try {
        $phoenix = Get-Content -Raw -Path $PhoenixPathInner | ConvertFrom-Json
    } catch {
        Write-Diag "ERROR reading phoenix.json: $($_.Exception.Message)"
        return @{ Healthy = $false; Reason = "phoenix.json read error"; Status = $null }
    }

    # Resolve local node by NodeRole; if NodeRole is wrong, attempt hostname/IP matching and safe fallbacks
    $localNode = $phoenix.Nodes | Where-Object { $_.Name -eq $phoenix.NodeRole } | Select-Object -First 1
    $localHostName = [System.Net.Dns]::GetHostName()

    if (-not $localNode) {
        Write-Diag "NodeRole '$($phoenix.NodeRole)' not found. Attempting to match by hostname $localHostName."
        $localNode = $phoenix.Nodes | Where-Object { $_.Name -eq $localHostName } | Select-Object -First 1
    }

    if (-not $localNode) {
        Write-Diag "No node matched NodeRole or hostname. Falling back to first non-localhost node entry."
        $localNode = $phoenix.Nodes | Where-Object { $_.ApiUrl -notmatch '127\.0\.0\.1|localhost' } | Select-Object -First 1
    }

    if (-not $localNode) {
        Write-Diag "No non-localhost node found; falling back to first node in Nodes array."
        $localNode = $phoenix.Nodes | Select-Object -First 1
    }

    if (-not $localNode) {
        Write-Diag "ERROR No nodes present in phoenix.json"
        return @{ Healthy = $false; Reason = "No nodes in phoenix.json"; Status = $null }
    }

    # If the resolved node's ApiUrl points to localhost but the machine is not that node, try alternatives
    if ($localNode.ApiUrl -match '127\.0\.0\.1|localhost') {
        if ($localNode.Name -ne $localHostName) {
            Write-Diag "Resolved node ApiUrl is localhost but machine hostname is $localHostName (node $($localNode.Name)). Searching for alternative node."
            $alt = $phoenix.Nodes | Where-Object { $_.Name -eq $localHostName } | Select-Object -First 1
            if ($alt) {
                Write-Diag "Switching to node matching hostname: $($alt.Name) ApiUrl=$($alt.ApiUrl)"
                $localNode = $alt
            } else {
                $remote = $phoenix.Nodes | Where-Object { $_.ApiUrl -notmatch '127\.0\.0\.1|localhost' } | Select-Object -First 1
                if ($remote) {
                    Write-Diag "Switching to first non-localhost node: $($remote.Name) ApiUrl=$($remote.ApiUrl)"
                    $localNode = $remote
                } else {
                    Write-Diag "No alternative node found; proceeding with localhost ApiUrl (may be intentional)."
                }
            }
        } else {
            Write-Diag "Resolved node ApiUrl is localhost and node name matches hostname; calling local Syncthing."
        }
    }

    # Prepare diagnostics
    $apiUrl = $localNode.ApiUrl
    $apiKey = $localNode.ApiKey
    $masked = Mask-Key $apiKey
    Write-Diag "Using NodeName=$($localNode.Name) NodeRole=$($phoenix.NodeRole) ApiUrl=$apiUrl ApiKeyMasked=$masked"

    if ($RevealApiKey) {
        Write-Diag "REVEAL MODE: Full ApiKey='$apiKey'"
    }

    # Attempt REST call
    try {
        $headers = @{ "X-API-Key" = $apiKey }
        Write-Diag "Attempting GET $apiUrl/rest/system/status"
        $resp = Invoke-RestMethod -Uri ("{0}/rest/system/status" -f $apiUrl.TrimEnd('/')) -Headers $headers -TimeoutSec 15

        # Short summary for log
        $respSummary = $resp | ConvertTo-Json -Depth 3
        if ($respSummary.Length -gt 2000) { $respSummary = $respSummary.Substring(0,2000) + "...(truncated)" }
        Write-Diag "Syncthing system status retrieved. Summary: $respSummary"

        return @{ Healthy = $true; Reason = "OK"; Status = $resp }
    }
    catch {
        $err = $_.Exception
        $status = $null
        $body = $null

        if ($err.Response -ne $null) {
            try {
                $status = $err.Response.StatusCode.Value__
                $body = $err.Response.Content.ReadAsStringAsync().Result
            } catch {
                $body = $err.Response.ToString()
            }
        }

        $msg = $err.Message
        Write-Diag "ERROR Failed to reach Syncthing API: $msg"
        if ($status) { Write-Diag "HTTP StatusCode: $status" }
        if ($body) {
            $b = $body
            if ($b.Length -gt 2000) { $b = $b.Substring(0,2000) + "...(truncated)" }
            Write-Diag "Response body: $b"
        }

        return @{ Healthy = $false; Reason = $msg; Status = $null }
    }
}

# --- If run directly, execute and update phoenix.json -----------------------
$health = phoenix-syncthing-health -PhoenixPathInner $PhoenixPath

try {
    $phoenix = Get-Content -Raw -Path $PhoenixPath | ConvertFrom-Json
} catch {
    Write-Diag "ERROR reading phoenix.json for update: $($_.Exception.Message)"
    throw
}

$now = Get-Date
$phoenix.Syncthing = $health
$phoenix.Phoenix.LastUpdate = $now.ToString("o")

try {
    $phoenix | ConvertTo-Json -Depth 8 | Set-Content -Path $PhoenixPath -Encoding UTF8
    Write-Diag "Syncthing health written to $PhoenixPath Healthy=$($health.Healthy) Reason=$($health.Reason)"
} catch {
    Write-Diag "ERROR writing phoenix.json: $($_.Exception.Message)"
}

Write-HealthLog -Message ("Syncthing health written to {0} Healthy={1} Reason={2}" -f $PhoenixPath, $health.Healthy, $health.Reason) -Level "INFO"
Write-Host "Syncthing health updated."
