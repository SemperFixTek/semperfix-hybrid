# Phoenix v2 — Windows Supervisor
# Monitors Syncthing API, Mesh health, and activation status.
# Writes supervisor-status.json for WSL + Windows coordination.

$ErrorActionPreference = "Stop"

# Paths
$PhoenixPath = "C:\SemperFix\ConfigBackup\phoenix.json"
$ConfigPath  = "C:\SemperFix\ConfigBackup\syncthing-config.json"
$StatusPath  = "C:\SemperFix\ConfigBackup\supervisor-status.json"

# Load Phoenix config
$phoenix = Get-Content $PhoenixPath | ConvertFrom-Json
$NodeRole = $phoenix.NodeRole
$ApiUrl   = $phoenix.ApiUrl

# Load Syncthing API key
$config = Get-Content $ConfigPath | ConvertFrom-Json
$ApiKey = $config.gui.apikey

# Prepare headers
$Headers = @{ "X-API-Key" = $ApiKey }

# Supervisor fields
$ApiOK       = $false
$StatusOK    = $false
$MeshOK      = $false
$ActivationOK = $false

# Check API ping
try {
    $pong = Invoke-RestMethod -Uri "$ApiUrl/rest/system/ping" -Headers $Headers -Method Get
    if ($pong -eq "pong") { $ApiOK = $true }
} catch {}

# Check system status
try {
    Invoke-RestMethod -Uri "$ApiUrl/rest/system/status" -Headers $Headers -Method Get | Out-Null
    $StatusOK = $true
} catch {}

# Mesh health (LAN ping)
try {
    $LanIP = ($ApiUrl.Split("/")[2].Split(":")[0])
    $MeshOK = Test-Connection -ComputerName $LanIP -Count 1 -Quiet
} catch {}

# Activation status (read last activation result)
$ActivationFile = "C:\SemperFix\ConfigBackup\activation-status.json"
if (Test-Path $ActivationFile) {
    try {
        $activation = Get-Content $ActivationFile | ConvertFrom-Json
        $ActivationOK = $activation.Activation.ActivationOK
    } catch {}
}

# Build supervisor JSON
$result = [ordered]@{
    NodeRole      = $NodeRole
    ApiUrl        = $ApiUrl
    Supervisor    = @{
        ApiOK        = $ApiOK
        StatusOK     = $StatusOK
        MeshOK       = $MeshOK
        ActivationOK = $ActivationOK
        Timestamp    = (Get-Date).ToString("o")
    }
}

# Write to file
$result | ConvertTo-Json -Depth 10 | Set-Content $StatusPath

# Also print to stdout for debugging
$result | ConvertTo-Json -Depth 10
