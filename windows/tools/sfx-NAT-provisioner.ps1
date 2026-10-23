Write-Host "=== SemperFix NAT Provisioner v4 (Host-Only) ===" -ForegroundColor Cyan

$SwitchName = "SemperFix-NAT"
$NatName    = "SemperFixNAT"
$Gateway    = "172.31.0.1"
$Prefix     = "172.31.0.0/24"

# 1. Create NAT switch (internal)
if (-not (Get-VMSwitch -Name $SwitchName -ErrorAction SilentlyContinue)) {
    Write-Host "Creating NAT switch: $SwitchName"
    New-VMSwitch -Name $SwitchName -SwitchType Internal
} else {
    Write-Host "Switch already exists: $SwitchName"
}

# 2. Assign gateway IP to host-side NAT adapter
$HostVnic = "vEthernet ($SwitchName)"
Write-Host "Assigning gateway $Gateway to $HostVnic"
New-NetIPAddress -InterfaceAlias $HostVnic -IPAddress $Gateway -PrefixLength 24 -ErrorAction SilentlyContinue

# 3. Create NAT network
if (-not (Get-NetNat -Name $NatName -ErrorAction SilentlyContinue)) {
    Write-Host "Creating NAT network: $NatName"
    New-NetNat -Name $NatName -InternalIPInterfaceAddressPrefix $Prefix
} else {
    Write-Host "NAT already exists: $NatName"
}

Write-Host "=== NAT v4 Setup Complete (Host-Only, No Wi-Fi Touch) ===" -ForegroundColor Green
