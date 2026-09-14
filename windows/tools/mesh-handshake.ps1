# Phoenix v2 — Mesh Handshake
$ErrorActionPreference = "Stop"

$phoenixPath = "C:\SemperFix\Phoenix\phoenix.json"
if (-not (Test-Path $phoenixPath)) {
    Write-Output '{"Error":"phoenix.json not found"}'
    exit 1
}

$phoenix = Get-Content $phoenixPath -Raw | ConvertFrom-Json

$apiUrl  = $phoenix.ApiUrl
$apiKey  = $phoenix.ApiKey
$role    = $phoenix.NodeRole

if (-not $apiUrl -or -not $apiKey -or -not $role) {
    Write-Output '{"Error":"phoenix.json missing required fields"}'
    exit 1
}

$headers = @{ "X-API-Key" = $apiKey }

$identityOK     = $false
$identityReason = ""
$deviceID       = ""

try {
    $statusJson = Invoke-RestMethod "$apiUrl/rest/system/status" -Headers $headers -TimeoutSec 4
    if ($statusJson.myID) {
        $identityOK = $true
        $deviceID   = $statusJson.myID
    }
    else {
        $identityReason = "Syncthing returned empty device ID"
    }
}
catch {
    $identityReason = "Syncthing status unreachable"
}

$endpointOK  = $false
$meshEndpoint = $phoenix.MeshEndpoint

if ($meshEndpoint) {
    try {
        $ep = $meshEndpoint.Replace("quic://","")
        $host, $port = $ep.Split(":")
        $client = New-Object System.Net.Sockets.TcpClient
        $client.Connect($host, [int]$port)
        $client.Close()
        $endpointOK = $true
    }
    catch {
        $endpointOK = $false
    }
}

$result = [ordered]@{
    NodeRole       = $role
    ApiUrl         = $apiUrl
    IdentityOK     = $identityOK
    IdentityReason = $identityReason
    DeviceID       = $deviceID
    EndpointOK     = $endpointOK
    Timestamp      = (Get-Date).ToString("o")
}

$result | ConvertTo-Json -Depth 10
