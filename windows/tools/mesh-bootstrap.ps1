# Phoenix v2 — Windows Mesh Bootstrap
$ErrorActionPreference = "Stop"

$configPath = "C:\SemperFix\ConfigBackup\phoenix.json"
$config = Get-Content $configPath | ConvertFrom-Json

$ApiUrl = $config.ApiUrl
$ApiKey = $config.ApiKey

# Check Syncthing API
$ApiOK = $false
try {
    $pong = Invoke-RestMethod "$ApiUrl/rest/system/ping" -Headers @{ "X-API-Key" = "$ApiKey" } -Method Get
    if ($pong.ping -eq "pong") { $ApiOK = $true }
} catch {
    Write-Host "ERROR: $($_.Exception.Message)"
}

Write-Host "Phoenix Bootstrap: Starting..."
Write-Host "Using ApiUrl: $ApiUrl"
Write-Host "Using API Key: $ApiKey"
Write-Host "Checking Syncthing API..."
Write-Host "Syncthing returned: $pong"

$result = [ordered]@{
    BootstrapOK = $ApiOK
    ApiUrl      = $ApiUrl
    ApiOK       = $ApiOK
    Timestamp   = (Get-Date).ToString("o")
}

$result | ConvertTo-Json -Depth 10
