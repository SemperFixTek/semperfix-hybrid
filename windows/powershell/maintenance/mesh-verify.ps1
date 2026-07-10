param(
    [string]$ConfigPath = "C:\SemperFix\Tools\semperfix-config.json"
)

$result = [ordered]@{
    NodeRole  = $null
    Timestamp = (Get-Date).ToString("o")
    Folders   = @()
    Healthy   = $false
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

# Folder status
try {
    $folders = Invoke-SyncthingApi -Path "/rest/db/status"

    if ($folders -is [System.Collections.IDictionary]) {
        foreach ($pair in $folders.GetEnumerator()) {
            $folder = $pair.Value
            $result.Folders += [ordered]@{
                FolderID    = $pair.Key
                GlobalBytes = $folder.globalBytes
                InSync      = ($folder.globalBytes -eq $folder.inSyncBytes)
            }
        }

        $result.Healthy = -not ($result.Folders | Where-Object { -not $_.InSync })
    }
}
catch {
    if ($_.Exception.Message -like "*404*") {
        # Golden Template empty state
        $result.Folders = @()
        $result.Healthy = $true
    }
    else {
        $result.Errors += "Folder status API failed: $($_.Exception.Message)"
    }
}

$result | ConvertTo-Json -Depth 6
