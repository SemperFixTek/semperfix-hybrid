# Phoenix v2 — Windows Mesh Verify
$ErrorActionPreference = "Stop"

$configPath = "C:\SemperFix\ConfigBackup\phoenix.json"
$config = Get-Content $configPath | ConvertFrom-Json

$ApiUrl = $config.ApiUrl

$ConfigOK = Test-Path "C:\SemperFix\ConfigBackup\syncthing-config.json"

$ServiceOK = $false
try {
    Invoke-RestMethod "$ApiUrl/rest/system/status" | Out-Null
    $ServiceOK = $true
} catch {}

$VerifyOK = $ConfigOK -and $ServiceOK

$result = [ordered]@{
    VerifyOK  = $VerifyOK
    ConfigOK  = $ConfigOK
    ServiceOK = $ServiceOK
}

$result | ConvertTo-Json -Depth 10
