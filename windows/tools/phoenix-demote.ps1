param(
    [string]$StatusPath = "C:\SemperFix\Config\phoenix-status.json",
    [string]$ConfigPath = "C:\SemperFix\tools\phoenix.json"
)

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$ts] [$Level] $Message"
}

function Load-Json {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        throw "File not found: '$Path'."
    }

    try {
        return (Get-Content -Raw -Path $Path | ConvertFrom-Json)
    }
    catch {
        throw "Invalid JSON in '$Path'."
    }
}

Write-Log "Phoenix demotion starting."

try {
    $status = Load-Json -Path $StatusPath
    $config = Load-Json -Path $ConfigPath

    $currentMaster = $config.MasterNode
    $oldMaster     = $config.Phoenix.Lineage

    if (-not $oldMaster) {
        throw "No lineage recorded; cannot determine old master."
    }

    $oldMasterStatus = $status.Nodes | Where-Object { $_.Name -eq $oldMaster }
    if (-not $oldMasterStatus) {
        throw "Old master '$oldMaster' not present in status."
    }

    if (-not $oldMasterStatus.Reachable) {
        throw "Cannot demote: old master '$oldMaster' is still unreachable."
    }

    Write-Log "Demoting old master '$oldMaster' to secondary; keeping '$currentMaster' as master."

    $config.NodeRole = "MASTERZERO"  # this node remains master; old master is just a node in Nodes
    # lineage stays as current master
    $config.Phoenix.Lineage = $currentMaster

    $json = $config | ConvertTo-Json -Depth 6
    Set-Content -Path $ConfigPath -Value $json -Encoding UTF8

    Write-Log "Phoenix demotion completed. Current master: '$currentMaster'; old master: '$oldMaster' now secondary."
}
catch {
    Write-Log "Phoenix demotion FAILED: $($_.Exception.Message)" "ERROR"
    exit 1
}
