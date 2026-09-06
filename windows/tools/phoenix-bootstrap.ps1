param(
    [string]$ConfigPath = "C:\SemperFix\tools\phoenix.json",
    [string]$StatusPath = "C:\SemperFix\Config\phoenix-status.json"
)

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$ts] [$Level] $Message"
}

function Load-PhoenixConfig {
    param([string]$Path)

    if (-not (Test-Path -Path $Path)) {
        throw "Phoenix config not found at '$Path'."
    }

    $raw = Get-Content -Path $Path -Raw
    try {
        $json = $raw | ConvertFrom-Json
    }
    catch {
        throw "Phoenix config at '$Path' is not valid JSON: $($_.Exception.Message)"
    }

    return $json
}

function Test-ClusterModel {
    param($Config)

    if (-not $Config.NodeRole)      { throw "Missing NodeRole in phoenix.json." }
    if (-not $Config.ClusterName)   { throw "Missing ClusterName in phoenix.json." }
    if (-not $Config.MasterNode)    { throw "Missing MasterNode in phoenix.json." }
    if (-not $Config.Nodes)         { throw "Missing Nodes array in phoenix.json." }
    if (-not $Config.Failover)      { throw "Missing Failover section in phoenix.json." }
    if (-not $Config.Phoenix)       { throw "Missing Phoenix section in phoenix.json." }

    if (-not $Config.Failover.Enabled) {
        Write-Log "Failover is disabled in phoenix.json." "WARN"
    }

    $master = $Config.Nodes | Where-Object { $_.Name -eq $Config.MasterNode }
    if (-not $master) {
        throw "MasterNode '$($Config.MasterNode)' not found in Nodes array."
    }

    return @{
        NodeRole    = $Config.NodeRole
        ClusterName = $Config.ClusterName
        MasterNode  = $Config.MasterNode
        Nodes       = $Config.Nodes
        Failover    = $Config.Failover
        PhoenixMeta = $Config.Phoenix
    }
}

function Test-SyncthingEndpoint {
    param($Node)

    if (-not $Node.ApiUrl) {
        return @{
            Name    = $Node.Name
            ApiUrl  = $null
            Reachable = $false
            Error   = "No ApiUrl defined."
        }
    }

    try {
        $resp = Invoke-WebRequest -Uri $Node.ApiUrl -Method Get -TimeoutSec 5
        return @{
            Name      = $Node.Name
            ApiUrl    = $Node.ApiUrl
            Reachable = $true
            Status    = $resp.StatusCode
        }
    }
    catch {
        return @{
            Name      = $Node.Name
            ApiUrl    = $Node.ApiUrl
            Reachable = $false
            Error     = $_.Exception.Message
        }
    }
}

function Write-PhoenixStatus {
    param($Model, $Health, [string]$Path)

    $status = [ordered]@{
        Timestamp    = (Get-Date).ToString("o")
        ClusterName  = $Model.ClusterName
        NodeRole     = $Model.NodeRole
        MasterNode   = $Model.MasterNode
        Failover     = $Model.Failover
        PhoenixMeta  = $Model.PhoenixMeta
        Nodes        = $Health
    }

    $json = $status | ConvertTo-Json -Depth 6
    $dir  = Split-Path -Path $Path -Parent
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    Set-Content -Path $Path -Value $json -Encoding UTF8
    Write-Log "Phoenix status written to '$Path'."
}

# --- main ---

Write-Log "Phoenix bootstrap starting."

try {
    $config = Load-PhoenixConfig -Path $ConfigPath
    $model  = Test-ClusterModel -Config $config

    Write-Log "Cluster: $($model.ClusterName) | Role: $($model.NodeRole) | Master: $($model.MasterNode)"

    $health = @()
    foreach ($node in $model.Nodes) {
        $h = Test-SyncthingEndpoint -Node $node
        $health += $h
        if ($h.Reachable) {
            Write-Log "Syncthing OK for node '$($h.Name)' at '$($h.ApiUrl)'."
        }
        else {
            Write-Log "Syncthing UNREACHABLE for node '$($h.Name)': $($h.Error)" "WARN"
        }
    }

    Write-PhoenixStatus -Model $model -Health $health -Path $StatusPath
    Write-Log "Phoenix bootstrap completed."
}
catch {
    Write-Log "Phoenix bootstrap FAILED: $($_.Exception.Message)" "ERROR"
    exit 1
}
