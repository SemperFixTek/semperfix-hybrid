<# 
    SemperFix Network Normalizer
    Forces all network adapters to Private
    Ensures firewall rules for Syncthing + Phoenix QUIC
    Version: Phoenix v2
#>

Write-Host "[INFO] SemperFix Network Normalizer starting..."

# -----------------------------
# Force all adapters to Private
# -----------------------------
$profiles = Get-NetConnectionProfile

foreach ($p in $profiles) {
    Write-Host "[INFO] Setting adapter '$($p.InterfaceAlias)' to Private..."
    try {
        Set-NetConnectionProfile -InterfaceAlias $p.InterfaceAlias -NetworkCategory Private -ErrorAction Stop
        Write-Host "[PASS] Adapter '$($p.InterfaceAlias)' is now Private."
    }
    catch {
        Write-Host "[FAIL] Could not set '$($p.InterfaceAlias)' to Private: $_"
    }
}

# -----------------------------
# Firewall Rules (Syncthing + Phoenix)
# -----------------------------
$rules = @(
    @{ Name="Syncthing-QUIC-UDP-22000"; Port=22000; Protocol="UDP" },
    @{ Name="Syncthing-TCP-22000";      Port=22000; Protocol="TCP" },
    @{ Name="Phoenix-QUIC-UDP-22001";   Port=22001; Protocol="UDP" }
)

foreach ($r in $rules) {
    Write-Host "[INFO] Ensuring firewall rule '$($r.Name)' exists..."

    $existing = Get-NetFirewallRule -DisplayName $r.Name -ErrorAction SilentlyContinue

    if (-not $existing) {
        New-NetFirewallRule `
            -DisplayName $r.Name `
            -Direction Inbound `
            -Action Allow `
            -Protocol $r.Protocol `
            -LocalPort $r.Port `
            -Profile Private `
            -ErrorAction Stop

        Write-Host "[PASS] Created firewall rule '$($r.Name)'."
    }
    else {
        Write-Host "[PASS] Firewall rule '$($r.Name)' already exists."
    }
}

Write-Host "[INFO] SemperFix Network Normalizer complete."
