$StateDir = "C:\SemperFix\state"
$LogDir   = "C:\SemperFix\logs"
$HeartbeatFile = Join-Path $StateDir "windows-heartbeat.json"
$LogFile       = Join-Path $LogDir "windows-heartbeat.log"

New-Item -ItemType Directory -Force -Path $StateDir, $LogDir | Out-Null

function Log($msg) {
    $line = "[INFO] $msg"
    $line | Tee-Object -FilePath $LogFile -Append
}

# ---------------------------------------------------------
# Load unified Phoenix config (from WSL)
# ---------------------------------------------------------
$phoenixPath = "\\wsl$\Ubuntu\opt\semperfix\config\phoenix.json"   # adjust distro name
if (-not (Test-Path $phoenixPath)) {
    Log "phoenix.json not found at $phoenixPath"
    exit 1
}

$phoenix = Get-Content $phoenixPath -Raw | ConvertFrom-Json

# Extract fields from actual phoenix.json structure
$node_role = $phoenix.node.role
$apiUrl    = $phoenix.syncthing.api_url
$apiKey    = $phoenix.syncthing.api_key
$peer_ip   = $phoenix.syncthing.peer_ip
$peer_port = $phoenix.syncthing.peer_port
$phoenix_quic_port = $phoenix.phoenix.quic_port

Log "Loaded Phoenix config: role=${node_role} apiUrl=${apiUrl} peer=${peer_ip}:${peer_port}"

# ---------------------------------------------------------
# Syncthing process check
# ---------------------------------------------------------
$syncthing = Get-Process -Name "syncthing" -ErrorAction SilentlyContinue
$syncthing_ok = if ($syncthing) { "true" } else { "false" }

# ---------------------------------------------------------
# Syncthing API check (corrected with API key)
# ---------------------------------------------------------
try {
    $pong = Invoke-WebRequest `
        -Uri "$apiUrl/system/ping" `
        -Headers @{ "X-API-Key" = $apiKey } `
        -UseBasicParsing `
        -TimeoutSec 3

    $syncthing_api_ok = if ($pong.Content -like "*pong*") { "true" } else { "false" }
} catch {
    $syncthing_api_ok = "false"
}

# ---------------------------------------------------------
# QUIC 22000 check (Syncthing QUIC listener)
# ---------------------------------------------------------
$quic_22000_ok = if (Get-NetUDPEndpoint | Where-Object { $_.LocalPort -eq $peer_port }) { "true" } else { "false" }

# ---------------------------------------------------------
# Windows IP
# ---------------------------------------------------------
$windows_ip = (Get-NetIPAddress -AddressFamily IPv4 |
               Where-Object { $_.InterfaceAlias -notlike "*Loopback*" -and $_.IPAddress -notlike "169.254.*" } |
               Select-Object -First 1 -ExpandProperty IPAddress)

# ---------------------------------------------------------
# WSL IP (from wsl-ip.txt)
# ---------------------------------------------------------
$wsl_ip = $null
$wslPath = "\\wsl$\Ubuntu\opt\semperfix\state\wsl-ip.txt"   # adjust distro name
if (Test-Path $wslPath) {
    $wsl_ip = Get-Content $wslPath -ErrorAction SilentlyContinue | Select-Object -First 1
}

# ---------------------------------------------------------
# Firewall check
# ---------------------------------------------------------
$fwProfile = Get-NetFirewallProfile -ErrorAction SilentlyContinue
$windows_firewall_ok = if ($fwProfile | Where-Object { $_.Enabled -eq $true }) { "true" } else { "false" }

# ---------------------------------------------------------
# Build JSON
# ---------------------------------------------------------
$heartbeat = [ordered]@{
    timestamp           = (Get-Date).ToString("s")
    node_role           = $node_role

    syncthing_ok        = $syncthing_ok
    syncthing_api_ok    = $syncthing_api_ok
    quic_22000_ok       = $quic_22000_ok

    windows_ip          = $windows_ip
    wsl_ip              = $wsl_ip

    windows_firewall_ok = $windows_firewall_ok

    peer_ip             = $peer_ip
    peer_port           = $peer_port
    phoenix_quic_port   = $phoenix_quic_port
}

$heartbeat | ConvertTo-Json -Depth 4 | Set-Content -Path $HeartbeatFile -Encoding UTF8
Log "Windows heartbeat written to $HeartbeatFile"
