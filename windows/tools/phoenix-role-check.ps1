# Phoenix Role Check — Updated to use global config loader

# 1. Import global Phoenix configuration
. "C:\SemperFix\tools\phoenix-config.ps1"

# 2. Load config from global object
$config = $Global:PhoenixConfig

# 3. Prepare output object
$result = [ordered]@{
    NodeRole  = $null
    Timestamp = (Get-Date).ToString("o")
    Valid     = $false
    Errors    = @()
}

# 4. Validate config loaded
if ($null -eq $config) {
    $result.Errors += "Config load failure: $Global:PhoenixConfigPath not readable"
    $result | ConvertTo-Json -Depth 6
    exit
}

# 5. Extract NodeRole
$nodeRole = $config.NodeRole

if ([string]::IsNullOrWhiteSpace($nodeRole)) {
    $result.Errors += "Unknown NodeRole: $nodeRole"
    $result | ConvertTo-Json -Depth 6
    exit
}

# 6. Validate NodeRole
$validRoles = @("MASTERZERO", "SECONDARY", "OFFSITE")

if ($validRoles -contains $nodeRole) {
    $result.NodeRole = $nodeRole
    $result.Valid    = $true
}
else {
    $result.Errors += "Unknown NodeRole: $nodeRole"
}

# 7. Output JSON
$result | ConvertTo-Json -Depth 6
