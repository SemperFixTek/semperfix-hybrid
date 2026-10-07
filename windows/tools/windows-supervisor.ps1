$StateDir = "C:\SemperFix\state"
$LogDir   = "C:\SemperFix\logs"
$SupFile  = Join-Path $StateDir "windows-supervisor.json"
$LogFile  = Join-Path $LogDir "windows-supervisor.log"

New-Item -ItemType Directory -Force -Path $StateDir, $LogDir | Out-Null

function Log($msg) {
    $line = "[INFO] $msg"
    $line | Tee-Object -FilePath $LogFile -Append
}

# ---------------------------------------------------------
# Load Phoenix config (for role/context)
# ---------------------------------------------------------
$phoenixPath = "\\wsl$\Ubuntu\opt\semperfix\config\phoenix.json"   # adjust distro name
if (-not (Test-Path $phoenixPath)) {
    Log "phoenix.json not found at $phoenixPath"
    exit 1
}

$phoenix   = Get-Content $phoenixPath -Raw | ConvertFrom-Json
$node_role = $phoenix.node.role

# ---------------------------------------------------------
# Load Windows heartbeat
# ---------------------------------------------------------
$winHbPath = Join-Path $StateDir "windows-heartbeat.json"
$winHb = if (Test-Path $winHbPath) {
    Get-Content $winHbPath -Raw | ConvertFrom-Json
} else {
    Log "Windows heartbeat not found at $winHbPath"
    $null
}

# ---------------------------------------------------------
# Load WSL heartbeat
# ---------------------------------------------------------
$wslHbPath = "\\wsl$\Ubuntu\var\lib\semperfix\state\phoenix-heartbeat.json"  # adjust distro
$wslHb = if (Test-Path $wslHbPath) {
    Get-Content $wslHbPath -Raw | ConvertFrom-Json
} else {
    Log "WSL heartbeat not found at $wslHbPath"
    $null
}

# ---------------------------------------------------------
# Extract Windows-side fields
# ---------------------------------------------------------
$windows_syncthing_ok = $winHb.syncthing_ok
$windows_api_ok       = $winHb.syncthing_api_ok
$windows_quic_ok      = $winHb.quic_22000_ok
$windows_firewall_ok  = $winHb.windows_firewall_ok
$windows_ip           = $winHb.windows_ip
$wsl_ip               = $winHb.wsl_ip

$peer_ip             = $winHb.peer_ip
$peer_port           = $winHb.peer_port
$phoenix_quic_port   = $winHb.phoenix_quic_port

# ---------------------------------------------------------
# Extract WSL-side fields
# ---------------------------------------------------------
$wsl_api_ok  = $wslHb.api_ok
$wsl_mesh_ok = $wslHb.mesh_ok

# ---------------------------------------------------------
# Compute overall_ok (role-aware if needed later)
# ---------------------------------------------------------
$overall_ok = if (
    $windows_syncthing_ok -eq "true" -and
    $windows_api_ok       -eq "true" -and
    $windows_quic_ok      -eq "true" -and
    $windows_firewall_ok  -eq "true" -and
    $wsl_api_ok           -eq "true" -and
    $wsl_mesh_ok          -eq "true"
) { "true" } else { "false" }

# ---------------------------------------------------------
# Build supervisor JSON
# ---------------------------------------------------------
$supervisor = [ordered]@{
    timestamp            = (Get-Date).ToString("s")
    node_role            = $node_role

    windows_syncthing_ok = $windows_syncthing_ok
    windows_api_ok       = $windows_api_ok
    windows_quic_ok      = $windows_quic_ok
    windows_firewall_ok  = $windows_firewall_ok
    windows_ip           = $windows_ip
    wsl_ip               = $wsl_ip

    wsl_api_ok           = $wsl_api_ok
    wsl_mesh_ok          = $wsl_mesh_ok

    peer_ip              = $peer_ip
    peer_port            = $peer_port
    phoenix_quic_port    = $phoenix_quic_port

    overall_ok           = $overall_ok
}

$supervisor | ConvertTo-Json -Depth 4 | Set-Content -Path $SupFile -Encoding UTF8
Log "Windows supervisor state written to $SupFile"
