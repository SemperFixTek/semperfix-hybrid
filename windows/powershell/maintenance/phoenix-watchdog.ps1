param(
    [string]$ConfigPath = "C:\SemperFix\Tools\semperfix-config.json"
)

try {
    $status = & "C:\SemperFix\Tools\node-status.ps1" -ConfigPath $ConfigPath | ConvertFrom-Json
}
catch {
    & "C:\SemperFix\Tools\phoenix-escalate.ps1" -Reason "Watchdog failure: $($_.Exception.Message)" -Stage "watchdog"
    exit
}

if (-not $status.ApiHealthy) {
    & "C:\SemperFix\Tools\phoenix-escalate.ps1" -Reason "Syncthing API unhealthy" -Stage "watchdog"
}
