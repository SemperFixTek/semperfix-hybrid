# Phoenix v2 — Failover Decision Engine
$ErrorActionPreference = "Stop"

$StatusPath    = "C:\SemperFix\ConfigBackup\phoenix-status.json"
$HeartbeatPath = "C:\SemperFix\ConfigBackup\phoenix-heartbeat.json"
$FailoverPath  = "C:\SemperFix\ConfigBackup\phoenix-failover.json"

$StatusOK = $false
$HeartbeatOK = $false

# Validate status
if (Test-Path $StatusPath) {
    try {
        $status = Get-Content $StatusPath | ConvertFrom-Json
        $StatusOK = $status.Status.ApiOK -and $status.Status.StatusOK
    } catch {}
}

# Validate heartbeat (must be < 2 minutes old)
if (Test-Path $HeartbeatPath) {
    try {
        $heartbeat = Get-Content $HeartbeatPath | ConvertFrom-Json
        $ts = [DateTime]::Parse($heartbeat.Timestamp)
        if ((Get-Date) - $ts -lt [TimeSpan]::FromMinutes(2)) {
            $HeartbeatOK = $true
        }
    } catch {}
}

$FailoverRequired = -not ($StatusOK -and $HeartbeatOK)

$result = [ordered]@{
    FailoverRequired = $FailoverRequired
    StatusOK         = $StatusOK
    HeartbeatOK      = $HeartbeatOK
    Timestamp        = (Get-Date).ToString("o")
}

$result | ConvertTo-Json -Depth 10 | Set-Content $FailoverPath
$result | ConvertTo-Json -Depth 10
