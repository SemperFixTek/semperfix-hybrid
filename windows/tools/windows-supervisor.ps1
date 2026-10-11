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
# Ensure WSL is running
# ---------------------------------------------------------
try {
    wsl.exe -d Ubuntu -- echo "WSL online" 2>$null | Out-Null
    Log "WSL started successfully"
} catch {
    Log "WSL failed to start"
}

# ---------------------------------------------------------
# Load Phoenix config (WSL-safe)
# ---------------------------------------------------------
try {
    $phoenixJson = wsl.exe -d Ubuntu cat "/opt/semperfix/config/phoenix.json" 2>$null
    if (-not $phoenixJson) {
        Log "phoenix.json missing or unreadable via WSL"
        $phoenix = $null
    } else {
        $phoenix = $phoenixJson | ConvertFrom-Json
    }
} catch {
    Log "Exception reading phoenix.json: $_"
    $phoenix = $null
}

$node_role = $phoenix.node.role

# ---------------------------------------------------------
# Load Windows heartbeat
# ---------------------------------------------------------
$winHbPath = Join-Path $StateDir "windows-heartbeat.json"
$winHb = if (Test-Path $winHbPath) {
    try {
        Get-Content $winHbPath -Raw | ConvertFrom-Json
    } catch {
        Log "Failed to parse Windows heartbeat JSON: $_"
        $null
    }
} else {
    Log "Windows heartbeat not found at $winHbPath"
    $null
}

# ---------------------------------------------------------
# Load WSL heartbeat (WSL-safe)
# ---------------------------------------------------------
try {
    $wslHbJson = wsl.exe -d Ubuntu cat "/var/lib/semperfix/state/phoenix-heartbeat.json" 2>$null
    if (-not $wslHbJson) {
        Log "WSL heartbeat missing or unreadable"
        $wslHb = $null
    } else {
        $wslHb = $wslHbJson | ConvertFrom-Json
    }
} catch {
    Log "Exception reading WSL heartbeat: $_"
    $wslHb = $null
}

# ---------------------------------------------------------
# Extract Windows-side fields (null-safe)
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
# Extract WSL-side fields (null-safe)
# ---------------------------------------------------------
$wsl_api_ok  = $wslHb.api_ok
$wsl_mesh_ok = $wslHb.mesh_ok

# ---------------------------------------------------------
# Compute overall_ok (null-safe)
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
