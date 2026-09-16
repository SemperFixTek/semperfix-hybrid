# SemperFix Scheduled Task Restore
# Phoenix v2 – SYSTEM Automation Tasks

$TaskPath = "C:\SemperFix\scheduled-tasks"

Write-Host "Restoring SemperFix automation tasks..." -ForegroundColor Cyan

$Tasks = @(
    "phoenix-heartbeat.xml",
    "phoenix-status-write.xml",
    "phoenix-supervisor.xml",
    "phoenix-failover.xml",
    "mesh-status.xml",
    "phoenix-status-validate.xml"
)
    
foreach ($t in $Tasks) {
    $xml = Join-Path $TaskPath $t

    if (Test-Path $xml) {
        Write-Host "Importing $t..." -ForegroundColor Yellow
        schtasks /Create /TN ("SemperFix\" + [IO.Path]::GetFileNameWithoutExtension($t)) /XML $xml /RU SYSTEM /F
    }
    else {
        Write-Host "Missing: $t" -ForegroundColor Red
    }
}

Write-Host "SemperFix automation tasks restored." -ForegroundColor Green
