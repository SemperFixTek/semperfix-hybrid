# Phoenix v2 — Mesh Status
$ErrorActionPreference = "Stop"

$phoenixPath = "C:\SemperFix\Phoenix\phoenix.json"
if (-not (Test-Path $phoenixPath)) {
    Write-Output '{"Error":"phoenix.json not found"}'
    exit 1
}

$phoenix = Get-Content $phoenixPath -Raw | ConvertFrom-Json

$apiUrl = $phoenix.ApiUrl
$apiKey = $phoenix.ApiKey
$role   = $phoenix.NodeRole

if (-not $apiUrl -or -not $apiKey -or -not $role) {
    Write-Output '{"Error":"phoenix.json missing required fields"}'
    exit 1
}

$headers = @{ "X-API-Key" = $apiKey }

$apiOK    = $false
$statusOK = $false

try {
    $pong = Invoke-RestMethod "$apiUrl/rest/system/ping" -Headers $headers -TimeoutSec 4
    if ($pong.ping -eq "pong") { $apiOK = $true }
}
catch {}

try {
    $status = Invoke-RestMethod "$apiUrl/rest/system/status" -Headers $headers -TimeoutSec 4
    if ($status.myID) { $statusOK = $true }
}
catch {}

$result = [ordered]@{
    NodeRole  = $role
    ApiUrl    = $apiUrl
    ApiOK     = $apiOK
    StatusOK  = $statusOK
    Timestamp = (Get-Date).ToString("o")
}

$result | ConvertTo-Json -Depth 10
