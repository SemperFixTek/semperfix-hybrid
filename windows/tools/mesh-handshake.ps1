param(
    [string]$ConfigPath = "/mnt/c/SemperFix/Tools/mesh-config.json"
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
    . "/mnt/c/SemperFix/Tools/syncthing-api.ps1" -ApiKey $ApiKey -BaseUrl $BaseUrl
}
catch {
    $result.Errors += "Failed to load syncthing-api.ps1: $($_.Exception.Message)"
    return ($result | ConvertTo-Json -Depth 6)
}

# Device connections (older Syncthing: /rest/system/connections)
try {
    $connections = Invoke-SyncthingApi -Path "/rest/system/connections"

    if ($connections.connections) {
        foreach ($pair in $connections.connections.PSObject.Properties) {
            $device = $pair.Value
            $result.Devices += [ordered]@{
                DeviceID  = $pair.Name
                Connected = $device.connected
                Address   = $device.address
                ClientVer = $device.clientVersion
                Type      = $device.type
            }
        }
    }
}
catch {
    $result.Errors += "Handshake failed: $($_.Exception.Message)"
}

$result | ConvertTo-Json -Depth 6
