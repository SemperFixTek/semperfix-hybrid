# Phoenix Mesh Status — Corrected for PSCustomObject enumeration

# 1. Import global Phoenix configuration
. "C:\SemperFix\Tools\mesh-config.json"

# 2. Load config from global object
$config = $Global:PhoenixConfig

# 3. Prepare output object
$mesh = [ordered]@{
    Timestamp    = (Get-Date).ToString("o")
    MeshHealthy  = $false
    DeviceCount  = 0
    Connected    = 0
    Errors       = @()
}

# 4. Validate config loaded
if ($null -eq $config) {
    $mesh.Errors += "Config load failure: $Global:PhoenixConfigPath not readable"
    $mesh | ConvertTo-Json -Depth 6
    exit
}

# 5. Extract API URL and key
$apiUrl = $config.ApiUrl
$apiKey = $config.ApiKey

if ([string]::IsNullOrWhiteSpace($apiUrl) -or
    [string]::IsNullOrWhiteSpace($apiKey)) {

    $mesh.Errors += "Invalid API configuration"
    $mesh | ConvertTo-Json -Depth 6
    exit
}

# 6. Build Syncthing API headers
$headers = @{
    "X-API-Key" = $apiKey
}

# 7. Query Syncthing API — /rest/system/connections
try {
    $connections = Invoke-RestMethod -Uri "$apiUrl/rest/system/connections" -Headers $headers -Method Get

    # PSCustomObject dictionary of deviceID → connectionInfo
    $connDict = $connections.connections

    # Correct PSCustomObject enumeration
    $connValues = $connDict.PSObject.Properties | ForEach-Object { $_.Value }

    $mesh.DeviceCount = $connValues.Count
    $mesh.Connected   = ($connValues | Where-Object { $_.connected -eq $true }).Count

    # Mesh is healthy if all peers are connected
    if ($mesh.DeviceCount -gt 0 -and $mesh.DeviceCount -eq $mesh.Connected) {
        $mesh.MeshHealthy = $true
    }
    else {
        $mesh.Errors += "Mesh incomplete: $($mesh.Connected) of $($mesh.DeviceCount) peers connected"
    }
}
catch {
    $mesh.Errors += "Mesh status API failed: $($_.Exception.Message)"
}

# 8. Output JSON
$mesh | ConvertTo-Json -Depth 6
