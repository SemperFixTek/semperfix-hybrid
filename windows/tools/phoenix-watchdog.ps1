# Phoenix Watchdog — Updated to use global config loader

# 1. Import global Phoenix configuration
. "C:\SemperFix\tools\phoenix-config.ps1"

$logDir = "C:\SemperFix\phoenix\logs"
$watchdogLog = Join-Path $logDir "watchdog.log"

if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

# 2. Load config from global object
$config = $Global:PhoenixConfig

if ($null -eq $config) {
    $heartbeat = [ordered]@{
        Timestamp      = (Get-Date).ToString("o")
        NodeRole       = $null
        ApiHealthy     = $false
        MeshHealthy    = $false
        DriftDetected  = $false
        FailoverAction = "ConfigLoadFailure"
        Errors         = @("Config load failure: $Global:PhoenixConfigPath not readable")
    }
    $heartbeat | ConvertTo-Json -Depth 6 | Add-Content -Path $watchdogLog
    exit
}

# 3. Node Status
try {
    $nodeStatus = & "C:\SemperFix\tools\node-status.ps1" | ConvertFrom-Json
}
catch {
    & "C:\SemperFix\tools\phoenix-escalate.ps1" -Reason "Watchdog failure: $($_.Exception.Message)" -Stage "watchdog"
    exit
}

# 4. Role Check
$role = & "C:\SemperFix\tools\phoenix-role-check.ps1" | ConvertFrom-Json

# 5. Mesh Check
$mesh = & "C:\SemperFix\tools\mesh-status.ps1" | ConvertFrom-Json

# 6. Drift Check
$driftDetected = $false
foreach ($folder in $nodeStatus.folders) {
    if ($folder.needFiles -gt 0) { $driftDetected = $true }
    if ($folder.localAdditions -gt 0) { $driftDetected = $true }
    if ($folder.failedItems -gt 0) { $driftDetected = $true }
}

# 7. Failover Simulation
$failover = & "C:\SemperFix\tools\phoenix-failover.ps1" -DryRun | ConvertFrom-Json

# 8. Build unified watchdog heartbeat
$heartbeat = [ordered]@{
    Timestamp      = (Get-Date).ToString("o")
    NodeRole       = $role.NodeRole
    ApiHealthy     = $nodeStatus.ApiHealthy
    MeshHealthy    = $mesh.MeshHealthy
    DriftDetected  = $driftDetected
    FailoverAction = $failover.Action
    Errors         = @()
}

# 9. Escalation logic
if (-not $nodeStatus.ApiHealthy) {
    & "C:\SemperFix\tools\phoenix-escalate.ps1" -Reason "Syncthing API unhealthy" -Stage "watchdog"
}

if (-not $mesh.MeshHealthy) {
    & "C:\SemperFix\tools\phoenix-escalate.ps1" -Reason "Mesh unhealthy" -Stage "watchdog"
}

if ($driftDetected) {
    & "C:\SemperFix\tools\phoenix-escalate.ps1" -Reason "Drift detected" -Stage "watchdog"
}

# 10. Write heartbeat log
$heartbeat | ConvertTo-Json -Depth 6 | Add-Content -Path $watchdogLog
