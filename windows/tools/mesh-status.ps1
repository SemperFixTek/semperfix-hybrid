# Phoenix v2 — Windows Mesh Status
$ErrorActionPreference = "Stop"

$configPath = "C:\SemperFix\ConfigBackup\phoenix.json"
$config = Get-Content $configPath | ConvertFrom-Json

$ApiUrl = $config.ApiUrl

# Identity
$IdentityOK = $true
$Hostname = $env:COMPUTERNAME

# Endpoint (QUIC)
$EndpointOK = $false
try {
    $client = New-Object System.Net.Sockets.TcpClient
    $client.Connect("10.10.10.2", 22000)
    $EndpointOK = $true
    $client.Close()
} catch {}

# Mesh health (LAN ping)
$MeshOK = Test-Connection -ComputerName ($ApiUrl.Split("/")[2].Split(":")[0]) -Count 1 -Quiet

$result = [ordered]@{
    Status = @{
        Hostname    = $Hostname
        IdentityOK  = $IdentityOK
        EndpointOK  = $EndpointOK
        MeshOK      = $MeshOK
    }
}

$result | ConvertTo-Json -Depth 10
