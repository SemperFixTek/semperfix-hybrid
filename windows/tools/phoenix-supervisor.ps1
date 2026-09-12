<#
    phoenix-supervisor.ps1
    Drop‑in supervisor with explicit MASTERZERO recovery logic.

    - Reads phoenix.json
    - Logs current view
    - Decides role changes
    - Writes phoenix.json atomically
#>

param(
    [string]$PhoenixPath = "C:\SemperFix\ConfigBackup\phoenix.json",
    [string]$LogPath     = "C:\SemperFix\Logs\supervisor.log"
)

function Write-SupervisorLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )

    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[{0}] [{1}] {2}" -f $ts, $Level, $Message
    Add-Content -Path $LogPath -Value $line -Encoding UTF8
}

function Write-PhoenixJson {
    param(
        [object]$Phoenix,
        [string]$Path
    )

    $tmp = "$Path.tmp"
    $Phoenix | ConvertTo-Json -Depth 12 | Set-Content -Path $tmp -Encoding UTF8
    Move-Item -Path $tmp -Destination $Path -Force
}

function Invoke-PhoenixSupervisor {
    param(
        [string]$PhoenixPathInner = $PhoenixPath
    )

    if (-not (Test-Path $PhoenixPathInner)) {
        Write-SupervisorLog -Message "phoenix.json missing at $PhoenixPathInner" -Level "ERROR"
        return
    }

    $phoenix = Get-Content -Raw -Path $PhoenixPathInner | ConvertFrom-Json

    $nodeRole    = $phoenix.NodeRole
    $statusRole  = $phoenix.Status.Role
    $statusState = $phoenix.Status.State
    $synHealthy  = $phoenix.Syncthing.Healthy

    Write-SupervisorLog -Message ("Supervisor view: NodeRole={0} StatusRole={1} State={2}" -f $nodeRole, $statusRole, $statusState)

    # --- MASTERZERO RECOVERY BRANCH ---
    # MASTERZERO is healthy but stuck in SECONDARY-ACTIVE/DEGRADED → reclaim control.
    if ($nodeRole -eq 'MASTERZERO' -and
        $statusRole -eq 'SECONDARY-ACTIVE' -and
        $synHealthy -eq $true)
    {
        Write-SupervisorLog -Message "Recovery: MASTERZERO is healthy but marked SECONDARY-ACTIVE. Reclaiming control."

        $phoenix.Status.Role       = 'MASTERZERO-ACTIVE'
        $phoenix.Status.State      = 'HEALTHY'
        $phoenix.Status.Message    = 'Recovery: MASTERZERO reclaimed primary role.'
        $phoenix.Status.Timestamp  = (Get-Date).ToString('o')
        $phoenix.Phoenix.Lineage   = 'MASTERZERO'

        Write-PhoenixJson -Phoenix $phoenix -Path $PhoenixPathInner
        Write-SupervisorLog -Message "Recovery write completed. Role=MASTERZERO-ACTIVE State=HEALTHY."
        return
    }

    # --- SECONDARY PROMOTION (example, keep your existing logic here) ---
    # If SECONDARY node, healthy, and currently PASSIVE, you might promote:
    if ($nodeRole -eq 'SECONDARY' -and
        $statusRole -eq 'SECONDARY-PASSIVE' -and
        $synHealthy -eq $true)
    {
        Write-SupervisorLog -Message "Promotion: SECONDARY is healthy and PASSIVE. Promoting to SECONDARY-ACTIVE."

        $phoenix.Status.Role       = 'SECONDARY-ACTIVE'
        $phoenix.Status.State      = 'HEALTHY'
        $phoenix.Status.Message    = 'Promotion: SECONDARY became active.'
        $phoenix.Status.Timestamp  = (Get-Date).ToString('o')
        $phoenix.Phoenix.Lineage   = 'SECONDARY'

        Write-PhoenixJson -Phoenix $phoenix -Path $PhoenixPathInner
        Write-SupervisorLog -Message "Promotion write completed. Role=SECONDARY-ACTIVE State=HEALTHY."
        return
    }

    # --- DEFAULT: no change ---
    Write-SupervisorLog -Message "No role change required."
}

# direct run
Invoke-PhoenixSupervisor -PhoenixPathInner $PhoenixPath
