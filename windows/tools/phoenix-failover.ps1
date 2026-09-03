# Phoenix Failover — Updated to use global config loader

# 1. Import global Phoenix configuration
. "C:\SemperFix\tools\phoenix-config.ps1"

# 2. Load config from global object
$config = $Global:PhoenixConfig

# 3. Prepare output object
$result = [ordered]@{
    Timestamp     = (Get-Date).ToString("o")
    NodeRole      = $null
    ProposedRole  = $null
    Action        = "Unknown NodeRole"
    FailoverReady = $false
    Errors        = @()
}

# 4. Validate config loaded
if ($null -eq $config) {
    $result.Errors += "Config load failure: $Global:PhoenixConfigPath not readable"
    $result | ConvertTo-Json -Depth 6
    exit
}

# 5. Extract NodeRole
$nodeRole = $config.NodeRole

if ([string]::IsNullOrWhiteSpace($nodeRole)) {
    $result.Errors += "Unknown NodeRole: $nodeRole"
    $result | ConvertTo-Json -Depth 6
    exit
}

$result.NodeRole = $nodeRole

# 6. Failover logic (unchanged — only config loading updated)
switch ($nodeRole) {

    "MASTERZERO" {
        $result.ProposedRole = "MASTERZERO"
        $result.Action       = "No failover — primary node"
        $result.FailoverReady = $true
    }

    "SECONDARY" {
        $result.ProposedRole = "MASTERZERO"
        $result.Action       = "Promote SECONDARY → MASTERZERO (DryRun)"
        $result.FailoverReady = $true
    }

    "OFFSITE" {
        $result.ProposedRole = "SECONDARY"
        $result.Action       = "OFFSITE continuity only (DryRun)"
        $result.FailoverReady = $true
    }

    default {
        $result.Errors += "Unknown NodeRole: $nodeRole"
    }
}

# 7. Output JSON
$result | ConvertTo-Json -Depth 6
