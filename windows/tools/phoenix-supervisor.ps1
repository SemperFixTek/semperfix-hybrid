# Phoenix v2 — Windows Supervisor
$ErrorActionPreference = "Stop"

$configPath = "C:\SemperFix\ConfigBackup\phoenix.json"
$config = Get-Content $configPath | ConvertFrom-Json

$ApiUrl = $config.ApiUrl
$ApiKey = $config.ApiKey

$Headers = @{ "X-API-Key" = "$ApiKey" }

$ApiOK = $false
$StatusOK = $false

try {
    $pong = Invoke-RestMethod "$ApiUrl/rest/system/ping" -Headers $Headers
    if ($pong.ping -eq "pong") { $ApiOK = $true }
} catch {}

try {
    $status = Invoke-RestMethod "$ApiUrl/rest/system/status" -Headers $Headers
    if ($status.myID) { $StatusOK = $true }
} catch {}

$result = [ordered]@{
    SupervisorOK = ($ApiOK -and $StatusOK)
    ApiOK        = $ApiOK
    StatusOK     = $StatusOK
    ApiUrl       = $ApiUrl
    Timestamp    = (Get-Date).ToString("o")
}

$result | ConvertTo-Json -Depth 10
