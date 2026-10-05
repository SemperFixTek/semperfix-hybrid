# Phoenix v2 — Heartbeat
$ErrorActionPreference = "Stop"

$HeartbeatPath = "C:\SemperFix\Logs\phoenix-heartbeat.json"

$result = [ordered]@{
    Alive     = $true
    Timestamp = (Get-Date).ToString("o")
}

$result | ConvertTo-Json -Depth 10 | Set-Content $HeartbeatPath
$result | ConvertTo-Json -Depth 10
