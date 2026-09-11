<#
 Mesh v2 — mesh-bootstrap.ps1 (MASTERZERO)
 Node-local bootstrap validation
 Writes ONLY to phoenix.masterzero.json
#>

Set-Location "C:\SemperFix\Tools"

$PhoenixRoot = "C:\SemperFix\ConfigBackup"

# ------------------------------------------------------------
# SELECT PHOENIX FILE (cluster or full topology only)
# ------------------------------------------------------------
$phoenixFile = Get-ChildItem $PhoenixRoot -Filter "phoenix*.json" |
    Where-Object {
        $_.Name -eq "phoenix.json" -or
        $_.Name -eq "phoenix.cluster.json"
    } |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

if (-not $phoenixFile) {
    Write-Output "{""Error"":""No usable phoenix.json or phoenix.cluster.json found""}"
    exit 1
}

$phoenixJson = Get-Content $phoenixFile.FullName -Raw | ConvertFrom-Json

# ------------------------------------------------------------
# DETERMINE NODE ROLE
# ------------------------------------------------------------
$nodeRole = $phoenixJson.NodeRole
if (-not $nodeRole) {
    Write-Output "{""Error"":""NodeRole missing in phoenix file""}"
    exit 1
}

# MASTERZERO only
$nodeLocalPath = "$PhoenixRoot\phoenix.masterzero.json"

# ------------------------------------------------------------
# EXTRACT NODE ENTRY (cluster or single-node schema)
# ------------------------------------------------------------
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

# ------------------------------------------------------------
# ENVIRONMENT CHECKS
# ------------------------------------------------------------

# 1. Syncthing API reachability
$apiOK = $false
try {
    $pong = Invoke-RestMethod -Uri "$apiUrl/rest/system/ping" -TimeoutSec 5
    $apiOK = ($pong -eq "pong")
}
catch {
    $apiOK = $false
}

# 2. QUIC endpoint reachability
function Test-QuicEndpoint {
    param($endpoint)

    try {
        $client = New-Object System.Net.Sockets.TcpClient
        $host, $port = $endpoint.Replace("quic://","").Split(":")
        $client.Connect($host, [int]$port)
        $client.Close()
        return $true
    }
    catch {
        return $false
    }
}

$quicOK = Test-QuicEndpoint $meshEndpoint

# 3. WSL availability
$wslOK = $false
try {
    $wslOut = wsl.exe -e bash -c "echo WSL_OK" 2>$null
    if ($wslOut -match "WSL_OK") {
        $wslOK = $true
    }
}
catch {
    $wslOK = $false
}

# ------------------------------------------------------------
# UPDATE NODE-LOCAL MESH BOOTSTRAP STATE
# ------------------------------------------------------------
$phoenixJson.Mesh = @{
    BootstrapOK       = ($apiOK -and $quicOK -and $wslOK)
    ApiReachable      = $apiOK
    QuicReachable     = $quicOK
    WslAvailable      = $wslOK
    LastBootstrap     = (Get-Date).ToString("o")
    LastError         = $null
}

# ------------------------------------------------------------
# WRITE NODE-LOCAL FILE (MASTERZERO ONLY)
# ------------------------------------------------------------
$phoenixJson | ConvertTo-Json -Depth 10 | Set-Content $nodeLocalPath -Encoding UTF8

# ------------------------------------------------------------
# OUTPUT PURE JSON FOR jq
# ------------------------------------------------------------
$phoenixJson.Mesh | ConvertTo-Json -Depth 10