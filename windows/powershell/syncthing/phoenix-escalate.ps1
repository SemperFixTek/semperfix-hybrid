param(
    [string]$Reason,
    [string]$Stage = "watchdog",
    [string]$ConfigPath = "C:\SemperFix\Tools\semperfix-config.json"
)

$result = [ordered]@{
    NodeRole  = $null
    Stage     = $Stage
    Reason    = $Reason
    Timestamp = (Get-Date).ToString("o")
    Errors    = @()
}

try {
    $config = Get-Content $ConfigPath | ConvertFrom-Json
    $result.NodeRole = $config.NodeRole
}
catch {
    $result.Errors += "Config load failed: $($_.Exception.Message)"
}

$result | ConvertTo-Json -Depth 6
