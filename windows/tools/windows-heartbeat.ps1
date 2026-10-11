$StateDir      = "C:\SemperFix\state"
$LogDir        = "C:\SemperFix\logs"
$HeartbeatFile = Join-Path $StateDir "windows-heartbeat.json"
$LogFile       = Join-Path $LogDir "windows-heartbeat.log"

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
    Log "WSL failed to start: $_"
}

# ---------------------------------------------------------
# Load unified Phoenix config (WSL-safe)
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

$node_role         = $phoenix.node.role
$apiUrl            = $phoenix.syncthing.api_url
$apiKey            = $phoenix.syncthing.api_key
$peer_ip           = $phoenix.syncthing.peer_ip
$peer_port         = $phoenix.syncthing.peer_port
$phoenix_quic_port = $phoenix.phoenix.quic_port

Log "Loaded Phoenix config: role=${node_role} apiUrl=${apiUrl} peer=${peer_ip}:${peer_port}"

# ---------------------------------------------------------
# Syncthing process check
# ---------------------------------------------------------
$syncthing    = Get-Process -Name "syncthing" -ErrorAction SilentlyContinue
$syncthing_ok = if ($syncthing) { "true" } else { "false" }

# ---------------------------------------------------------
# Syncthing API check (with API key)
# ---------------------------------------------------------
try {
    $pong = Invoke-WebRequest `
        -Uri "$apiUrl/system/ping" `
        -Headers @{ "X-API-Key" = $apiKey } `
        -UseBasicParsing `
        -TimeoutSec 3

    $syncthing_api_ok = if ($pong.Content -like "*pong*") { "true" } else { "false" }
} catch {
    Log "Syncthing API ping failed: $_"
    $syncthing_api_ok = "false"
}

# ---------------------------------------------------------
# QUIC 22000 check (Syncthing QUIC listener)
# ---------------------------------------------------------
try {
    $quic_22000_ok = if (Get-NetUDPEndpoint | Where-Object { $_.LocalPort -eq $peer_port }) { "true" } else { "false" }
} catch {
    Log "QUIC endpoint check failed: $_"
    $quic_22000_ok = "false"
}

# ---------------------------------------------------------
# Windows IP
# ---------------------------------------------------------
try {
    $windows_ip = (Get-NetIPAddress -AddressFamily IPv4 |
                   Where-Object { $_.InterfaceAlias -notlike "*Loopback*" -and $_.IPAddress -notlike "169.254.*" } |
                   Select-Object -First 1 -ExpandProperty IPAddress)
} catch {
    Log "Windows IP detection failed: $_"
    $windows_ip = $null
}

# ---------------------------------------------------------
# WSL IP (from WSL, not UNC)
# ---------------------------------------------------------
$wsl_ip = $null
try {
    $wslIpText = wsl.exe -d Ubuntu cat "/opt/semperfix/state/wsl-ip.txt" 2>$null
    if ($wslIpText) {
        $wsl_ip = ($wslIpText -split "`n")[0]
    } else {
        Log "wsl-ip.txt missing or empty via WSL"
    }
} catch {
    Log "WSL IP read failed: $_"
}

# ---------------------------------------------------------
# Firewall check
# ---------------------------------------------------------
try {
    $fwProfile           = Get-NetFirewallProfile -ErrorAction SilentlyContinue
    $windows_firewall_ok = if ($fwProfile | Where-Object { $_.Enabled -eq $true }) { "true" } else { "false" }
} catch {
    Log "Firewall profile check failed: $_"
    $windows_firewall_ok = "false"
}

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
