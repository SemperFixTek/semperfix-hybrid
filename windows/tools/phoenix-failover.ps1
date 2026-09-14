# Phoenix v2 — Failover Engine
$ErrorActionPreference = "Stop"

$statusPath    = "C:\SemperFix\ConfigBackup\phoenix-status.json"
$heartbeatPath = "C:\SemperFix\ConfigBackup\phoenix-heartbeat.json"
$failoverPath  = "C:\SemperFix\ConfigBackup\phoenix-failover.json"

$StatusOK    = $false
$HeartbeatOK = $false

if (Test-Path $statusPath) {
    try {
        $status = Get-Content $statusPath -Raw | ConvertFrom-Json
        if ($status.ApiOK -and $status.StatusOK) {
            $StatusOK = $true
        }
    }
    catch {}
}

if (Test-Path $heartbeatPath) {
    try {
        $hb = Get-Content $heartbeatPath -Raw | ConvertFrom-Json
        $ts = [DateTime]::Parse($hb.Timestamp)
        if ((Get-Date) - $ts -lt [TimeSpan]::FromMinutes(2)) {
            $HeartbeatOK = $true
        }
    }
    catch {}
}

$FailoverRequired = -not ($StatusOK -and $HeartbeatOK)

$result = [ordered]@{
    FailoverRequired = $FailoverRequired
    StatusOK         = $StatusOK
    HeartbeatOK      = $HeartbeatOK
    Timestamp        = (Get-Date).ToString("o")
}

$result | ConvertTo-Json -Depth 10 | Set-Content $failoverPath
$result | ConvertTo-Json -Depth 10
