# Phoenix v2 — Status Validator
$ErrorActionPreference = "Stop"

$statusPath = "C:\SemperFix\ConfigBackup\phoenix-status.json"

if (-not (Test-Path $statusPath)) {
    Write-Output '{"Valid":false,"Reason":"Missing phoenix-status.json"}'
    exit
}

try {
    $status = Get-Content $statusPath | ConvertFrom-Json
} catch {
    Write-Output '{"Valid":false,"Reason":"Unreadable or invalid JSON"}'
    exit
}

$Valid = ($status.ApiOK -and $status.StatusOK)

$result = [ordered]@{
    Valid     = $Valid
    ApiOK     = $status.ApiOK
    StatusOK  = $status.StatusOK
    ApiUrl    = $status.ApiUrl
    Timestamp = (Get-Date).ToString("o")
}

$result | ConvertTo-Json -Depth 10
