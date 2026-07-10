param(
    [string]$ConfigPath = "C:\SemperFix\Tools\semperfix-config.json"
)

$result = [ordered]@{
    NodeRole     = $null
    Timestamp    = (Get-Date).ToString("o")
    ApiHealthy   = $false
    EmptyState   = $false
    Devices      = 0
    Folders      = 0
    Message      = ""
    Errors       = @()
}

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

. "C:\SemperFix\Tools\syncthing-api.ps1" -ApiKey $ApiKey -BaseUrl $BaseUrl

try {
    Invoke-SyncthingApi -Path "/rest/system/status" | Out-Null
    $result.ApiHealthy = $true
}
catch {
    $result.Errors += "System status API failed: $($_.Exception.Message)"
    return ($result | ConvertTo-Json -Depth 6)
}

try {
    $connections = Invoke-SyncthingApi -Path "/rest/system/connections"
    if ($connections.connections -is [System.Collections.IDictionary]) {
        $result.Devices = $connections.connections.Count
    }
}
catch {}

try {
    $folders = Invoke-SyncthingApi -Path "/rest/db/status"
    if ($folders -is [System.Collections.IDictionary]) {
        $result.Folders = $folders.Count
    }
}
catch {
    if ($_.Exception.Message -like "*404*") {
        $result.Folders = 0
    }
}

if ($result.Devices -eq 0 -and $result.Folders -eq 0) {
    $result.EmptyState = $true
    $result.Message = "Syncthing is healthy but empty — Golden Template state detected."
} else {
    $result.EmptyState = $false
    $result.Message = "Syncthing has active devices/folders."
}

$result | ConvertTo-Json -Depth 6
