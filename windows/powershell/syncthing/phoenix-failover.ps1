param(
    [switch]$DryRun,
    [string]$ConfigPath = "C:\SemperFix\Tools\semperfix-config.json"
)

$result = [ordered]@{
    NodeRole  = $null
    DryRun    = $DryRun.IsPresent
    Timestamp = (Get-Date).ToString("o")
    Action    = ""
    Errors    = @()
}

try {
    $config = Get-Content $ConfigPath | ConvertFrom-Json
    $result.NodeRole = $config.NodeRole

    switch ($config.NodeRole) {
        "MASTERZERO" { $result.Action = "Promote SECONDARY (conceptual only)" }
        "SECONDARY"  { $result.Action = "Rely on MASTERZERO and OFFSITE" }
        "OFFSITE"    { $result.Action = "Remote continuity only" }
        default      { $result.Action = "Unknown NodeRole" }
    }
}
catch {
    $result.Errors += "Config load failed: $($_.Exception.Message)"
}

$result | ConvertTo-Json -Depth 6
