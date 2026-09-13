# Phoenix v2 — Windows Mesh Verify
$ErrorActionPreference = "Stop"

# Load Phoenix v2 config
$configPath = "C:\SemperFix\ConfigBackup\phoenix.json"
$config = Get-Content $configPath | ConvertFrom-Json

$ApiUrl = $config.ApiUrl
$ApiKey = $config.ApiKey

# Check that the Phoenix v2 config file exists
$ConfigOK = Test-Path $configPath

# Check Syncthing API
$ServiceOK = $false
try {
    $status = Invoke-RestMethod "$ApiUrl/rest/system/status" -Headers @{ "X-API-Key" = $ApiKey }
    if ($status.myID) { $ServiceOK = $true }
} catch {
    Write-Host "Mesh Verify Error: $($_.Exception.Message)"
}

# Final verification result
$VerifyOK = $ConfigOK -and $ServiceOK

$result = [ordered]@{
    VerifyOK  = $VerifyOK
    ConfigOK  = $ConfigOK
    ServiceOK = $ServiceOK
    ApiUrl    = $ApiUrl
    Timestamp = (Get-Date).ToString("o")
}

$result | ConvertTo-Json -Depth 10
