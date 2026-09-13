<#
    phoenix-status-validate.ps1 (Unified Config Edition)
    Validates phoenix.json structure and key Phoenix/Status fields.
#>

param(
    [string]$PhoenixPath = "C:\SemperFix\ConfigBackup\phoenix.json"
)

if (-not (Test-Path $PhoenixPath)) {
    Write-Host "ERROR: phoenix.json missing at $PhoenixPath"
    exit 1
}

try {
    $phoenix = Get-Content -Raw -Path $PhoenixPath | ConvertFrom-Json
} catch {
    Write-Host "ERROR: Failed to parse phoenix.json: $($_.Exception.Message)"
    exit 1
}

$errors = @()

# Core identity
if (-not $phoenix.NodeRole)      { $errors += "Missing NodeRole" }
if (-not $phoenix.ClusterName)   { $errors += "Missing ClusterName" }
if (-not $phoenix.MasterNode)    { $errors += "Missing MasterNode" }

# Nodes
if (-not $phoenix.Nodes -or $phoenix.Nodes.Count -lt 2) {
    $errors += "Nodes array missing or incomplete"
} else {
    foreach ($n in $phoenix.Nodes) {
        if (-not $n.Name)    { $errors += "Node missing Name" }
        if (-not $n.ApiUrl)  { $errors += "Node $($n.Name) missing ApiUrl" }
        if (-not $n.ApiKey)  { $errors += "Node $($n.Name) missing ApiKey" }
    }
}

# Failover
if (-not $phoenix.Failover) { $errors += "Missing Failover section" }

# Watchdog
if (-not $phoenix.Watchdog) { $errors += "Missing Watchdog section" }

# Phoenix block
if (-not $phoenix.Phoenix)           { $errors += "Missing Phoenix section" }
if (-not $phoenix.Phoenix.Lineage)   { $errors += "Missing Phoenix.Lineage" }

# Status block
if (-not $phoenix.Status)        { $errors += "Missing Status section" }
else {
    if (-not $phoenix.Status.Role)  { $errors += "Missing Status.Role" }
    if (-not $phoenix.Status.State) { $errors += "Missing Status.State" }
}

# Health / Syncthing / Actions
if (-not $phoenix.Syncthing) { $errors += "Missing Syncthing section" }
if (-not $phoenix.Health)    { $errors += "Missing Health section" }
if (-not $phoenix.Actions)   { $errors += "Missing Actions section" }

if ($errors.Count -gt 0) {
    Write-Host "phoenix.json validation FAILED:"
    $errors | ForEach-Object { Write-Host " - $_" }
    exit 1
}

Write-Host "phoenix.json validation OK."
exit 0
