param(
    [string]$StatusPath = "C:\SemperFix\Config\phoenix-status.json"
)

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$ts] [$Level] $Message"
}

function Load-Status {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        throw "Phoenix status not found at '$Path'."
    }

    try {
        return (Get-Content -Raw -Path $Path | ConvertFrom-Json)
    }
    catch {
        throw "Invalid JSON in '$Path'."
    }
}

Write-Log "Phoenix verify starting."

try {
    $status = Load-Status -Path $StatusPath

    if (-not $status.Failover.Enabled) {
        throw "Failover is disabled in phoenix.json."
    }

    $master = $status.Nodes | Where-Object { $_.Name -eq $status.MasterNode }
    if (-not $master) {
        throw "MasterNode '$($status.MasterNode)' not found in status."
    }

    if (-not $master.Reachable) {
        throw "MasterNode '$($status.MasterNode)' is not reachable."
    }

    foreach ($node in $status.Nodes) {
        if (-not $node.Reachable) {
            Write-Log "Node '$($node.Name)' unreachable." "WARN"
        }
    }

    Write-Log "Phoenix verify passed. Failover can be safely enabled."
}
catch {
    Write-Log "Phoenix verify FAILED: $($_.Exception.Message)" "ERROR"
    exit 1
}
