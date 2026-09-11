# mesh-handshake.ps1 — Final Version (auto-detects correct Phoenix file)

# Ensure $phoenix exists
if (-not $script:phoenix) {
    $script:phoenix = [PSCustomObject]@{ Mesh = @{} }
}
elseif (-not ($script:phoenix.PSObject.Properties.Name -contains 'Mesh')) {
    $script:phoenix | Add-Member -MemberType NoteProperty -Name Mesh -Value @{}
}

# Resolve working directory
try {
    if ($IsWindows) {
        Set-Location -LiteralPath (Join-Path $PSScriptRoot ".")
    } else {
        $wslPath = "/mnt/c/SemperFix/Tools"
        if (Test-Path $wslPath) { Set-Location $wslPath }
    }
}
catch {
    Write-Output "{""Error"":""Unable to set working directory""}"
    exit 1
}

# Locate Phoenix files (ConfigBackup)
$phoenixPath = if ($IsWindows) {
    "C:\SemperFix\ConfigBackup"
} else {
    "/mnt/c/SemperFix\ConfigBackup"
}

# Pick correct Phoenix file (cluster or full topology)
$phoenixFile = Get-ChildItem $phoenixPath -Filter "phoenix*.json" |
    Where-Object {
        $_.Name -eq "phoenix.json" -or
        $_.Name -eq "phoenix.cluster.json"
    } |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1



$phoenixJson = Get-Content $phoenixFile.FullName -Raw | ConvertFrom-Json

# Determine NodeRole
$nodeRole = $phoenixJson.NodeRole
if (-not $nodeRole) {
    Write-Output "{""Error"":""NodeRole missing in phoenix file""}"
    exit 1
}

# Extract node entry (cluster or single-node schema)
if ($phoenixJson.Nodes) {
    $nodeEntry = $phoenixJson.Nodes | Where-Object { $_.Name -eq $nodeRole }
} else {
    $nodeEntry = $phoenixJson
}

if (-not $nodeEntry) {
    Write-Output "{""Error"":""Node entry not found for role $nodeRole""}"
    exit 1
}

$apiUrl       = $nodeEntry.ApiUrl
$meshEndpoint = $nodeEntry.MeshEndpoint

# Syncthing identity check
$identityOK     = $false
$identityReason = ""
$deviceID       = ""

try {
    $statusJson = Invoke-RestMethod -Uri "$apiUrl/rest/system/status" -TimeoutSec 4 -ErrorAction Stop
    if ($statusJson.myID) {
        $identityOK = $true
        $deviceID   = $statusJson.myID
    } else {
        $identityReason = "Syncthing returned empty device ID"
    }
}
catch {
    $identityReason = "Syncthing status unreachable"
}

# QUIC endpoint check
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

# Build OtherEndpoints
$other = @{}

if ($phoenixJson.Nodes) {
    foreach ($n in $phoenixJson.Nodes) {
        if ($n.Name -ne $nodeRole) {
            $other[$n.Name] = [PSCustomObject]@{
                ApiUrl       = $n.ApiUrl
                MeshEndpoint = $n.MeshEndpoint
            }
        }
    }
}

# Populate phoenix.Mesh
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

# Output JSON
$script:phoenix | ConvertTo-Json -Depth 10
