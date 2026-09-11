# mesh-handshake.ps1 — Patched Version
# Safe for Windows PowerShell and WSL pwsh

# ------------------------------------------------------------
# Ensure $phoenix exists and has a Mesh property
# ------------------------------------------------------------
if (-not $script:phoenix) {
    $script:phoenix = [PSCustomObject]@{ Mesh = @{} }
}
elseif (-not ($script:phoenix.PSObject.Properties.Name -contains 'Mesh')) {
    $script:phoenix | Add-Member -MemberType NoteProperty -Name Mesh -Value @{}
}

# ------------------------------------------------------------
# Resolve working directory safely
# ------------------------------------------------------------
try {
    if ($IsWindows) {
        Set-Location -LiteralPath (Join-Path $PSScriptRoot ".")
    }
    else {
        # WSL pwsh cannot see C:\, so use /mnt/c
        $wslPath = "/mnt/c/SemperFix/Tools"
        if (Test-Path $wslPath) {
            Set-Location $wslPath
        }
    }
}
catch {
    Write-Output "{""Error"":""Unable to set working directory""}"
    exit 1
}

# ------------------------------------------------------------
# Load Phoenix JSON (Windows-side)
# ------------------------------------------------------------
$phoenixPath = if ($IsWindows) {
    "C:\SemperFix\ConfigBackup"
} else {
    "/mnt/c/SemperFix/ConfigBackup"
}

$phoenixFile = Get-ChildItem $phoenixPath -Filter "phoenix.*.json" -ErrorAction SilentlyContinue |
               Select-Object -First 1

if (-not $phoenixFile) {
    Write-Output "{""Error"":""No phoenix.<node>.json found""}"
    exit 1
}

$phoenixJson = Get-Content $phoenixFile.FullName -Raw | ConvertFrom-Json

# ------------------------------------------------------------
# Extract NodeRole, ApiUrl, MeshEndpoint
# ------------------------------------------------------------
$nodeRole = $phoenixJson.NodeRole
if (-not $nodeRole) {
    Write-Output "{""Error"":""NodeRole missing in phoenix file""}"
    exit 1
}

$nodeEntry = $phoenixJson.Nodes | Where-Object { $_.Name -eq $nodeRole }

if (-not $nodeEntry) {
    Write-Output "{""Error"":""Node entry not found for role $nodeRole""}"
    exit 1
}

$apiUrl       = $nodeEntry.ApiUrl
$meshEndpoint = $nodeEntry.MeshEndpoint

# ------------------------------------------------------------
# Syncthing identity check
# ------------------------------------------------------------
$identityOK     = $false
$identityReason = ""
$deviceID       = ""

try {
    $statusJson = Invoke-RestMethod -Uri "$apiUrl/rest/system/status" -TimeoutSec 4 -ErrorAction Stop
    if ($statusJson.myID) {
        $identityOK = $true
        $deviceID   = $statusJson.myID
    }
    else {
        $identityReason = "Syncthing returned empty device ID"
    }
}
catch {
    $identityReason = "Syncthing status unreachable"
}

# ------------------------------------------------------------
# QUIC endpoint check
# ------------------------------------------------------------
$endpointOK = $false

try {
    $ep = $meshEndpoint.Replace("quic://","")
    $host, $port = $ep.Split(":")
    $client = New-Object System.Net.Sockets.TcpClient
    $client.Connect($host, [int]$port)
    $client.Close()
    $endpointOK = $true
}
catch {
    $endpointOK = $false
}

# ------------------------------------------------------------
# Build OtherEndpoints object
# ------------------------------------------------------------
$other = @{}

foreach ($n in $phoenixJson.Nodes) {
    if ($n.Name -ne $nodeRole) {
        $other[$n.Name] = [PSCustomObject]@{
            ApiUrl       = $n.ApiUrl
            MeshEndpoint = $n.MeshEndpoint
        }
    }
}

# ------------------------------------------------------------
# Populate phoenix.Mesh
# ------------------------------------------------------------
$script:phoenix.Mesh = [PSCustomObject]@{
    NodeRole      = $nodeRole
    IdentityOK    = $identityOK
    IdentityReason= $identityReason
    DeviceID      = $deviceID
    EndpointOK    = $endpointOK
    MyEndpoint    = $meshEndpoint
    OtherEndpoints= $other
    Timestamp     = (Get-Date).ToString("o")
}

# ------------------------------------------------------------
# Output JSON cleanly
# ------------------------------------------------------------
$script:phoenix | ConvertTo-Json -Depth 10
