# Phoenix v2 — Status Writer
$ErrorActionPreference = "Stop"

$PhoenixPath = "C:\SemperFix\ConfigBackup\phoenix.json"
$ConfigPath  = "C:\SemperFix\ConfigBackup\syncthing-config.json"
$StatusPath  = "C:\SemperFix\ConfigBackup\phoenix-status.json"

$phoenix = Get-Content $PhoenixPath | ConvertFrom-Json
$NodeRole = $phoenix.NodeRole
$ApiUrl   = $phoenix.ApiUrl

$config = Get-Content $ConfigPath | ConvertFrom-Json
$ApiKey = $config.gui.apikey

$Headers = @{ "X-API-Key" = $ApiKey }

$ApiOK = $false
$StatusOK = $false

try {
    $pong = Invoke-RestMethod "$ApiUrl/rest/system/ping" -Headers $Headers
    if ($pong -eq "pong") { $ApiOK = $true }
} catch {}

try {
    Invoke-RestMethod "$ApiUrl/rest/system/status" -Headers $Headers | Out-Null
    $StatusOK = $true
} catch {}

$result = [ordered]@{
    NodeRole = $NodeRole
    ApiUrl   = $ApiUrl
    Status   = @{
        ApiOK     = $ApiOK
        StatusOK  = $StatusOK
        Timestamp = (Get-Date).ToString("o")
    }
}

$result | ConvertTo-Json -Depth 10 | Set-Content $StatusPath
$result | ConvertTo-Json -Depth 10
