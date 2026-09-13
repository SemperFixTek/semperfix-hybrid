# Phoenix v2 — Windows Mesh Activate
$ErrorActionPreference = "Stop"

$configPath = "C:\SemperFix\ConfigBackup\phoenix.json"
$config = Get-Content $configPath | ConvertFrom-Json

$ApiUrl = $config.ApiUrl
$ApiKey = $config.ApiKey

$Headers = @{ "X-API-Key" = "$ApiKey" }

$ActivationOK = $false

try {
    $status = Invoke-RestMethod "$ApiUrl/rest/system/status" -Headers $Headers
    if ($status.myID) { $ActivationOK = $true }
} catch {}

$result = [ordered]@{
    ActivationOK = $ActivationOK
    ApiUrl       = $ApiUrl
    Timestamp    = (Get-Date).ToString("o")
}

$result | ConvertTo-Json -Depth 10
