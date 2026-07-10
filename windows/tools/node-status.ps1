param(
    [string]$ConfigPath = "C:\SemperFix\Tools\semperfix-config.json"
)

$result = [ordered]@{
    NodeRole     = $null
    Timestamp    = (Get-Date).ToString("o")
    ApiHealthy   = $false
    DeviceCount  = 0
    FolderCount  = 0
    Errors       = @()
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

# Check system status
try {
    $system = Invoke-SyncthingApi -Path "/rest/system/status"
    $result.ApiHealthy = $true
}
catch {
    $result.Errors += "System status API failed: $($_.Exception.Message)"
}

# Check device connections
try {
    $connections = Invoke-SyncthingApi -Path "/rest/system/connections"

    if ($connections.connections -is [System.Collections.IDictionary]) {
        $result.DeviceCount = $connections.connections.Count
    }
}
catch {
    $result.Errors += "Device connections API failed: $($_.Exception.Message)"
}

# Check folder status (Golden Template–safe)
try {
    $folders = Invoke-SyncthingApi -Path "/rest/db/status"

    if ($folders -is [System.Collections.IDictionary]) {
        $result.FolderCount = $folders.Count
    }
}
catch {
    if ($_.Exception.Message -like "*404*") {
        $result.FolderCount = 0
    }
    else {
        $result.Errors += "Folder status API failed: $($_.Exception.Message)"
    }
}

$result | ConvertTo-Json -Depth 6
