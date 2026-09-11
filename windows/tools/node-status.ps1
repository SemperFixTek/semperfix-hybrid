# Phoenix Node Status — Unified Edition

# 1. Load unified Phoenix config
$phoenixPath = "C:\SemperFix\ConfigBackup\phoenix.json"

if (!(Test-Path $phoenixPath)) {
    Write-Host "ERROR: phoenix.json not found at $phoenixPath"
    exit 1
}

$config = Get-Content $phoenixPath -Raw | ConvertFrom-Json

# 2. Determine this node's identity
$nodeName = $config.NodeRole
$nodeInfo = $config.Nodes | Where-Object { $_.Name -eq $nodeName }

if ($null -eq $nodeInfo) {
    Write-Host "ERROR: NodeRole '$nodeName' not found in phoenix.json Nodes[]"
    exit 1
}

$apiUrl = $nodeInfo.ApiUrl
$apiKey = $nodeInfo.ApiKey

# 3. Prepare output object
$result = [ordered]@{
    Timestamp          = (Get-Date).ToString("o")

    # Phoenix identity
    NodeRole           = $config.NodeRole
    PhoenixRole        = $config.Status.Role
    PhoenixState       = $config.Status.State
    PhoenixMessage     = $config.Status.Message

    # Phoenix health
    MeshHealthy        = $config.Syncthing.Status.Healthy
    SyncthingReason    = $config.Syncthing.Status.Reason

    DiskOK             = $config.Health.DiskOK
    PathsOK            = $config.Health.PathsOK
    FilesOK            = $config.Health.FilesOK
    ModulesOK          = $config.Health.ModulesOK
    FoldersOK          = $config.Health.FoldersOK

    # Syncthing live API health
    ApiHealthy         = $false
    Version            = $null
    DeviceCount        = 0
    FolderCount        = 0
    Peers              = @()
    Folders            = @()
    Errors             = @()
}

# 4. Validate API config
if ([string]::IsNullOrWhiteSpace($apiUrl) -or
    [string]::IsNullOrWhiteSpace($apiKey)) {

    $result.Errors += "Invalid API configuration in phoenix.json"
    $result | ConvertTo-Json -Depth 6
    exit
}

$headers = @{ "X-API-Key" = $apiKey }

# 5. Syncthing system status
try {
    $sys = Invoke-RestMethod -Uri "$apiUrl/rest/system/status" -Headers $headers -Method Get
    $result.ApiHealthy  = $true
    $result.DeviceCount = $sys.numConnections
}
catch {
    $result.Errors += "System status API failed: $($_.Exception.Message)"
}

# 6. Syncthing version
try {
    $ver = Invoke-RestMethod -Uri "$apiUrl/rest/system/version" -Headers $headers -Method Get
    $result.Version = $ver.version
}
catch {
    $result.Errors += "Version API failed: $($_.Exception.Message)"
}

# 7. Syncthing peers
try {
    $peers = Invoke-RestMethod -Uri "$apiUrl/rest/system/peers" -Headers $headers -Method Get
    $result.Peers = $peers
}
catch {
    $result.Errors += "Peers API failed: $($_.Exception.Message)"
}

# 8. Syncthing folder config
try {
    $cfg = Invoke-RestMethod -Uri "$apiUrl/rest/system/config" -Headers $headers -Method Get
    $result.FolderCount = $cfg.folders.Count
    $result.Folders     = $cfg.folders
}
catch {
    $result.Errors += "Folder status API failed: $($_.Exception.Message)"
}

# 9. Output JSON
$result | ConvertTo-Json -Depth 6
