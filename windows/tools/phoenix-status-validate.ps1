<#
    phoenix-status-validate.ps1
    Validates phoenix-status.json v2 structure and key fields.
#>

param(
    [string]$StatusPath = "C:\SemperFix\ConfigBackup\phoenix-status.json"
)

if (-not (Test-Path $StatusPath)) {
    Write-Host "ERROR: Status file missing at $StatusPath"
    exit 1
}

try {
    $status = Get-Content -Raw -Path $StatusPath | ConvertFrom-Json
} catch {
    Write-Host "ERROR: Failed to parse JSON: $($_.Exception.Message)"
    exit 1
}

$errors = @()

if (-not $status.Role)   { $errors += "Missing Role" }
if (-not $status.Status) { $errors += "Missing Status" }

if (-not $status.Node.Name)        { $errors += "Missing Node.Name" }
if (-not $status.Node.LastUpdated) { $errors += "Missing Node.LastUpdated" }

if (-not $status.Cluster.MasterNode)    { $errors += "Missing Cluster.MasterNode" }
if (-not $status.Cluster.SecondaryNode) { $errors += "Missing Cluster.SecondaryNode" }

if (-not $status.Syncthing) { $errors += "Missing Syncthing section" }
if (-not $status.Health)    { $errors += "Missing Health section" }
if (-not $status.Actions)   { $errors += "Missing Actions section" }
if (-not $status.Meta)      { $errors += "Missing Meta section" }

if ($errors.Count -gt 0) {
    Write-Host "phoenix-status.json v2 validation FAILED:"
    $errors | ForEach-Object { Write-Host " - $_" }
    exit 1
}

Write-Host "phoenix-status.json v2 validation OK."
exit 0
