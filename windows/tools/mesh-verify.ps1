# Phoenix v2 — Mesh Verify
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

$verifyOK = $false
$reason   = ""

try {
    $cfg = Invoke-RestMethod "$apiUrl/rest/system/config" -Headers $headers -TimeoutSec 4
    if ($cfg.gui.enabled -and $cfg.gui.address) {
        $verifyOK = $true
    }
    else {
        $reason = "GUI not enabled or address missing"
    }
}
catch {
    $reason = "Syncthing config unreachable"
}

$result = [ordered]@{
    NodeRole   = $role
    ApiUrl     = $apiUrl
    VerifyOK   = $verifyOK
    VerifyReason = $reason
    Timestamp  = (Get-Date).ToString("o")
}

$result | ConvertTo-Json -Depth 10
