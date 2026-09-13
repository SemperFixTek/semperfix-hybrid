# Phoenix v2 — Heartbeat
$ErrorActionPreference = "Stop"

$HeartbeatPath = "C:\SemperFix\ConfigBackup\phoenix-heartbeat.json"

$result = [ordered]@{
    Alive     = $true
    Timestamp = (Get-Date).ToString("o")
}

$result | ConvertTo-Json -Depth 10 | Set-Content $HeartbeatPath
$result | ConvertTo-Json -Depth 10
