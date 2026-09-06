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

Write-Log "Phoenix promotion starting."

try {
    $status = Load-Json -Path $StatusPath
    $config = Load-Json -Path $ConfigPath

    $masterName    = $status.MasterNode
    $secondaryName = ($status.Nodes | Where-Object { $_.Name -ne $masterName }).Name

    $masterStatus    = $status.Nodes | Where-Object { $_.Name -eq $masterName }
    $secondaryStatus = $status.Nodes | Where-Object { $_.Name -eq $secondaryName }

    if ($masterStatus.Reachable) {
        throw "Cannot promote: current master '$masterName' is still reachable."
    }

    if (-not $secondaryStatus.Reachable) {
        throw "Cannot promote: secondary '$secondaryName' is not reachable."
    }

    Write-Log "Promoting '$secondaryName' to master."

    $config.MasterNode = $secondaryName
    $config.NodeRole   = "MASTERZERO"
    $config.Phoenix.Lineage = $secondaryName

    $json = $config | ConvertTo-Json -Depth 6
    Set-Content -Path $ConfigPath -Value $json -Encoding UTF8

    Write-Log "Phoenix promotion completed. New master: '$secondaryName'."
}
catch {
    Write-Log "Phoenix promotion FAILED: $($_.Exception.Message)" "ERROR"
    exit 1
}
