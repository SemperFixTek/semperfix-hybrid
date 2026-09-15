# Phoenix v2 — Supervisor
$ErrorActionPreference = "Stop"

# ------------------------------------------------------------
# Load phoenix.json (correct v2 path + schema)
# ------------------------------------------------------------
$PhoenixPath = "C:\SemperFix\Phoenix\phoenix.json"

if (-Not (Test-Path $PhoenixPath)) {
    Write-Host "[Supervisor] ✖ phoenix.json missing"
    exit 1
}

try {
    $Phoenix = Get-Content $PhoenixPath -Raw | ConvertFrom-Json
}
catch {
    Write-Host "[Supervisor] ✖ phoenix.json invalid JSON"
    exit 1
}

$NodeRole = $Phoenix.NodeRole
$ApiUrl   = $Phoenix.ApiUrl
$ApiKey   = $Phoenix.ApiKey

# ------------------------------------------------------------
# Normalize firewall profiles (v2 requirement)
# ------------------------------------------------------------
try {
    $profiles = Get-NetConnectionProfile
    foreach ($p in $profiles) {
        if ($p.NetworkCategory -ne "Private") {
            Write-Host "[Supervisor] Normalizing firewall profile for $($p.InterfaceAlias)..."
            Set-NetConnectionProfile -InterfaceAlias $p.InterfaceAlias -NetworkCategory Private
        }
    }
}
catch {
    Write-Host "[Supervisor] ✖ Firewall normalization failed: $_"
}

# ------------------------------------------------------------
# Syncthing API health check (dynamic endpoint + required headers)
# ------------------------------------------------------------
$Headers = @{
    "X-API-Key" = $ApiKey
}

$SystemStatusUrl = "$ApiUrl/rest/system/status"

$ApiOK = $false
$StatusOK = $false

try {
    $response = Invoke-RestMethod -Uri $SystemStatusUrl -Method Get -Headers $Headers -TimeoutSec 5
    $ApiOK = $true

    if ($response.myID) {
        $StatusOK = $true
    }
}
catch {
    $ApiOK = $false
    $StatusOK = $false
}

# ------------------------------------------------------------
# Write supervisor status JSON
# ------------------------------------------------------------
$statusPath = "C:\SemperFix\ConfigBackup\phoenix-status.json"

$result = [ordered]@{
    SupervisorOK = ($ApiOK -and $StatusOK)
    ApiOK        = $ApiOK
    StatusOK     = $StatusOK
    ApiUrl       = $ApiUrl
    NodeRole     = $NodeRole
    Timestamp    = (Get-Date).ToString("o")
}

$result | ConvertTo-Json -Depth 10 | Out-File $statusPath -Encoding UTF8

Write-Host "[Supervisor] Status written"
