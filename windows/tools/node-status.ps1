# Phoenix Node Status — Updated to use global config loader

# 1. Import global Phoenix configuration
. "C:\SemperFix\tools\phoenix-config.ps1"

# 2. Load config from global object
$config = $Global:PhoenixConfig

# 3. Prepare output object
$result = [ordered]@{
    Timestamp    = (Get-Date).ToString("o")
    ApiHealthy   = $false
    DeviceCount  = 0
    FolderCount  = 0
    Errors       = @()
    folders      = @()
}

# 4. Validate config loaded
if ($null -eq $config) {
    $result.Errors += "Config load failure: $Global:PhoenixConfigPath not readable"
    $result | ConvertTo-Json -Depth 6
    exit
}

# 5. Extract API URL and key
$apiUrl = $config.ApiUrl
$apiKey = $config.ApiKey

if ([string]::IsNullOrWhiteSpace($apiUrl) -or
    [string]::IsNullOrWhiteSpace($apiKey)) {

    $result.Errors += "Invalid API configuration"
    $result | ConvertTo-Json -Depth 6
    exit
}

# 6. Build Syncthing API headers
$headers = @{
    "X-API-Key" = $apiKey
}

# 7. Query Syncthing API — /rest/system/status
try {
    $sys = Invoke-RestMethod -Uri "$apiUrl/rest/system/status" -Headers $headers -Method Get
    $result.ApiHealthy = $true
    $result.DeviceCount = $sys.numConnections
}
catch {
    $result.Errors += "System status API failed: $($_.Exception.Message)"
}

# 8. Query Syncthing API — /rest/system/config
try {
    $cfg = Invoke-RestMethod -Uri "$apiUrl/rest/system/config" -Headers $headers -Method Get
    $result.FolderCount = $cfg.folders.Count
    $result.folders     = $cfg.folders
}
catch {
    $result.Errors += "Folder status API failed: $($_.Exception.Message)"
}

# 9. Output JSON
$result | ConvertTo-Json -Depth 6
