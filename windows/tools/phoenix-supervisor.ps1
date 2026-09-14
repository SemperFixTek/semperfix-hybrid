# Phoenix v2 — Supervisor
$ErrorActionPreference = "Stop"

$statusPath = "C:\SemperFix\ConfigBackup\phoenix-status.json"

$StatusOK = $false

if (Test-Path $statusPath) {
    try {
        $status = Get-Content $statusPath -Raw | ConvertFrom-Json
        if ($status.ApiOK -and $status.StatusOK) {
            $StatusOK = $true
        }
    }
    catch {}
}

$result = [ordered]@{
    SupervisorOK = $StatusOK
    ApiOK        = $status.ApiOK
    StatusOK     = $status.StatusOK
    ApiUrl       = $status.ApiUrl
    Timestamp    = (Get-Date).ToString("o")
}

$result | ConvertTo-Json -Depth 10
