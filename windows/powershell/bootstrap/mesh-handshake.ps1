param(
    [string]$ConfigPath = "C:\SemperFix\Tools\semperfix-config.json"
)

$result = [ordered]@{
    NodeRole  = $null
    Timestamp = (Get-Date).ToString("o")
    Devices   = @()
    Errors    = @()
}

# Load config
try {
    $config = Get-Content $ConfigPath | ConvertFrom-Json
    $ApiKey  = $config.ApiKey
    $BaseUrl = $config.BaseUrl
    $result.NodeRole = $config.NodeRole
}
catch {
    $result.Errors += "Config load failed: $($_.Exception.Message)"
    return ($result | ConvertTo-Json -Depth 6)
}

# Load API helper
try {
    . "C:\SemperFix\Tools\syncthing-api.ps1" -ApiKey $ApiKey -BaseUrl $BaseUrl
}
catch {
    $result.Errors += "Failed to load syncthing-api.ps1: $($_.Exception.Message)"
    return ($result | ConvertTo-Json -Depth 6)
}

# Device connections
try {
    $connections = Invoke-SyncthingApi -Path "/rest/system/connections"

    if ($connections.connections -is [System.Collections.IDictionary]) {
        foreach ($pair in $connections.connections.GetEnumerator()) {
            $result.Devices += [ordered]@{
                DeviceID  = $pair.Key
                Connected = $pair.Value.connected
                Address   = $pair.Value.address
            }
        }
    }
}
catch {
    $result.Errors += "Handshake failed: $($_.Exception.Message)"
}

$result | ConvertTo-Json -Depth 6
