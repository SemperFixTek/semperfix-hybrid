# Phoenix v2 — Status Validator
$ErrorActionPreference = "Stop"

$StatusPath = "C:\SemperFix\ConfigBackup\phoenix-status.json"

if (-not (Test-Path $StatusPath)) {
    Write-Output '{"Valid":false,"Reason":"Status file missing"}'
    exit
}

try {
    $status = Get-Content $StatusPath | ConvertFrom-Json
} catch {
    Write-Output '{"Valid":false,"Reason":"Status file unreadable"}'
    exit
}

$ApiOK    = $status.Status.ApiOK
$StatusOK = $status.Status.StatusOK

$Valid = $ApiOK -and $StatusOK

$result = [ordered]@{
    Valid     = $Valid
    ApiOK     = $ApiOK
    StatusOK  = $StatusOK
    Timestamp = (Get-Date).ToString("o")
}

$result | ConvertTo-Json -Depth 10
