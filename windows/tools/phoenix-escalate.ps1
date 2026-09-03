# Phoenix Escalation — Updated to use global config loader

# 1. Import global Phoenix configuration
. "C:\SemperFix\tools\phoenix-config.ps1"

param(
    [string]$Reason,
    [string]$Stage
)

# 2. Load config from global object
$config = $Global:PhoenixConfig

# 3. Prepare escalation event object (renamed from 'event')
$escalation = [ordered]@{
    Timestamp  = (Get-Date).ToString("o")
    NodeRole   = $null
    Stage      = $Stage
    Reason     = $Reason
    Errors     = @()
}

# 4. Validate config loaded
if ($null -eq $config) {
    $escalation.Errors += "Config load failure: $Global:PhoenixConfigPath not readable"
}
else {
    $escalation.NodeRole = $config.NodeRole
}

# 5. Write escalation event to log
$logDir = "C:\SemperFix\phoenix\logs"
$logFile = Join-Path $logDir "escalate.log"

if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

$escalation | ConvertTo-Json -Depth 6 | Add-Content -Path $logFile
