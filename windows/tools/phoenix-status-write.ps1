# Phoenix v2 — Status Writer
$ErrorActionPreference = "Stop"

$configPath = "C:\SemperFix\Phoenix\phoenix.json"
$statusPath = "C:\SemperFix\ConfigBackup\phoenix-status.json"

$cfg = Get-Content $configPath -Raw | ConvertFrom-Json

$ApiUrl = $cfg.ApiUrl
$ApiKey = $cfg.ApiKey

$Headers = @{ "X-API-Key" = $ApiKey }

$ApiOK    = $false
$StatusOK = $false

try {
    $pong = Invoke-RestMethod "$ApiUrl/rest/system/ping" -Headers $Headers -TimeoutSec 4
    if ($pong.ping -eq "pong") { $ApiOK = $true }
}
catch {}

try {
    $status = Invoke-RestMethod "$ApiUrl/rest/system/status" -Headers $Headers -TimeoutSec 4
    if ($status.myID) { $StatusOK = $true }
}
catch {}

$result = [ordered]@{
    ApiOK     = $ApiOK
    StatusOK  = $StatusOK
    ApiUrl    = $ApiUrl
    Timestamp = (Get-Date).ToString("o")
}

$result | ConvertTo-Json -Depth 10 | Set-Content $statusPath
$result | ConvertTo-Json -Depth 10
