# Phoenix Dry-Run — Updated to use global config loader

# 1. Import global Phoenix configuration
. "C:\SemperFix\tools\phoenix-config.ps1"

param(
    [switch]$Verbose
)

# 2. Load config from global object
$config = $Global:PhoenixConfig

# 3. Prepare output object
$result = [ordered]@{
    Timestamp      = (Get-Date).ToString("o")
    NodeRole       = $null
    ProposedRole   = $null
    FailoverReady  = $false
    MeshHealthy    = $false
    ApiHealthy     = $false
    Errors         = @()
}

# 4. Validate config loaded
if ($null -eq $config) {
    $result.Errors += "Config load failure: $Global:PhoenixConfigPath not readable"
    $result | ConvertTo-Json -Depth 6
    exit
}

# 5. Extract NodeRole
$nodeRole = $config.NodeRole
$result.NodeRole = $nodeRole

if ([string]::IsNullOrWhiteSpace($nodeRole)) {
    $result.Errors += "Unknown NodeRole: $nodeRole"
    $result | ConvertTo-Json -Depth 6
    exit
}

# 6. Run role-check module
$roleCheck = & "C:\SemperFix\tools\phoenix-role-check.ps1" | ConvertFrom-Json
if ($roleCheck.Valid -ne $true) {
    $result.Errors += "Role-check failed: $($roleCheck.Errors -join ', ')"
}

# 7. Run node-status module
$nodeStatus = & "C:\SemperFix\tools\node-status.ps1" | ConvertFrom-Json
$result.ApiHealthy = $nodeStatus.ApiHealthy

if (-not $nodeStatus.ApiHealthy) {
    $result.Errors += "API unhealthy during dry-run"
}

# 8. Run mesh-status module
$meshStatus = & "C:\SemperFix\tools\mesh-status.ps1" | ConvertFrom-Json
$result.MeshHealthy = $meshStatus.MeshHealthy

if (-not $meshStatus.MeshHealthy) {
    $result.Errors += "Mesh unhealthy during dry-run"
}

# 9. Failover simulation logic (unchanged)
switch ($nodeRole) {

    "MASTERZERO" {
        $result.ProposedRole = "MASTERZERO"
        $result.FailoverReady = $true
    }

    "SECONDARY" {
        $result.ProposedRole = "MASTERZERO"
        $result.FailoverReady = $true
    }

    "OFFSITE" {
        $result.ProposedRole = "SECONDARY"
        $result.FailoverReady = $true
    }

    default {
        $result.Errors += "Unknown NodeRole: $nodeRole"
    }
}

# 10. Output JSON
$result | ConvertTo-Json -Depth 6
