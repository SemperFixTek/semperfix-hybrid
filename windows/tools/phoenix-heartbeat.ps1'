# Phoenix v2 — Heartbeat
$ErrorActionPreference = "Stop"

$HeartbeatPath = "C:\SemperFix\ConfigBackup\phoenix-heartbeat.json"

$result = [ordered]@{
    Timestamp = (Get-Date).ToString("o")
    Alive     = $true
}

$result | ConvertTo-Json -Depth 10 | Set-Content $HeartbeatPath
$result | ConvertTo-Json -Depth 10
