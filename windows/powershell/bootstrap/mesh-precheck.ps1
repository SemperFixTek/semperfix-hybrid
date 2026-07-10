param(
    [string]$ConfigPath = "C:\SemperFix\Tools\semperfix-config.json"
)

$result = [ordered]@{
    NodeRole     = $null
    Timestamp    = (Get-Date).ToString("o")
    ApiHealthy   = $false
    ReadyForMesh = $false
    Devices      = 0
    Folders      = 0
    Message      = ""
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
    Invoke-SyncthingApi -Path "/rest/system/status" | Out-Null
    $result.ApiHealthy = $true
}
catch {
    $result.Errors += "System status API failed: $($_.Exception.Message)"
    return ($result | ConvertTo-Json -Depth 6)
}

# Check device connections
try {
    $connections = Invoke-SyncthingApi -Path "/rest/system/connections"
    if ($connections.connections -is [System.Collections.IDictionary]) {
        $result.Devices = $connections.connections.Count
    }
}
catch {
    # Empty state is valid — suppress unless non-404
    if ($_.Exception.Message -notlike "*404*") {
        $result.Errors += "Device API failed: $($_.Exception.Message)"
    }
}

# Check folder status
try {
    $folders = Invoke-SyncthingApi -Path "/rest/db/status"
    if ($folders -is [System.Collections.IDictionary]) {
        $result.Folders = $folders.Count
    }
}
catch {
    if ($_.Exception.Message -like "*404*") {
        # Golden Template empty state — no folders yet
        $result.Folders = 0
    }
    else {
        $result.Errors += "Folder status API failed: $($_.Exception.Message)"
    }
}

# Mesh readiness logic
if ($result.Devices -eq 0 -and $result.Folders -eq 0) {
    $result.ReadyForMesh = $true
    $result.Message = "Mesh not activated yet — ready for bootstrap."
} else {
    $result.ReadyForMesh = $false
    $result.Message = "Mesh or configuration already present — bootstrap not required."
}

$result | ConvertTo-Json -Depth 6
