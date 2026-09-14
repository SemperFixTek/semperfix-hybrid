# Phoenix v2 — Mesh Activate
$ErrorActionPreference = "Stop"

$phoenixPath = "C:\SemperFix\Phoenix\phoenix.json"
if (-not (Test-Path $phoenixPath)) {
    Write-Output '{"ActivationOK":false,"Reason":"phoenix.json not found"}'
    exit 1
}

$phoenix = Get-Content $phoenixPath -Raw | ConvertFrom-Json

$apiUrl = $phoenix.ApiUrl
$apiKey = $phoenix.ApiKey
$role   = $phoenix.NodeRole

if (-not $apiUrl -or -not $apiKey -or -not $role) {
    Write-Output '{"ActivationOK":false,"Reason":"phoenix.json missing required fields"}'
    exit 1
}

$headers = @{ "X-API-Key" = $apiKey }

$ok     = $false
$reason = ""

try {
    $pong = Invoke-RestMethod "$apiUrl/rest/system/ping" -Headers $headers -TimeoutSec 4
    if ($pong.ping -eq "pong") {
        $ok = $true
    }
    else {
        $reason = "Ping did not return pong"
    }
}
catch {
    $reason = "Syncthing ping unreachable"
}

$result = [ordered]@{
    ActivationOK = $ok
    Reason       = $reason
    ApiUrl       = $apiUrl
    NodeRole     = $role
    Timestamp    = (Get-Date).ToString("o")
}

$result | ConvertTo-Json -Depth 10
