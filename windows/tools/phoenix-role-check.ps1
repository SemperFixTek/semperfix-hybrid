param(
    [string]$ConfigPath = "C:\SemperFix\Tools\semperfix-config.json"
)

$result = [ordered]@{
    NodeRole  = $null
    Timestamp = (Get-Date).ToString("o")
    Valid     = $false
    Errors    = @()
}

try {
    $config = Get-Content $ConfigPath | ConvertFrom-Json
    $result.NodeRole = $config.NodeRole

    switch ($config.NodeRole) {
        "MASTERZERO" { $result.Valid = $true }
        "SECONDARY"  { $result.Valid = $true }
        "OFFSITE"    { $result.Valid = $true }
        default {
            $result.Valid = $false
            $result.Errors += "Unknown NodeRole: $($config.NodeRole)"
        }
    }
}
catch {
    $result.Errors += "Config load failed: $($_.Exception.Message)"
}

$result | ConvertTo-Json -Depth 6
