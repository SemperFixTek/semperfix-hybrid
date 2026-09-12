<<<<<<< HEAD
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
=======
# Phoenix v2 — Windows Supervisor
# Monitors Syncthing API, Mesh health, and activation status.
# Writes supervisor-status.json for WSL + Windows coordination.

$ErrorActionPreference = "Stop"

# Paths
$PhoenixPath = "C:\SemperFix\ConfigBackup\phoenix.json"
$ConfigPath  = "C:\SemperFix\ConfigBackup\syncthing-config.json"
$StatusPath  = "C:\SemperFix\ConfigBackup\supervisor-status.json"

# Load Phoenix config
$phoenix = Get-Content $PhoenixPath | ConvertFrom-Json
$NodeRole = $phoenix.NodeRole
$ApiUrl   = $phoenix.ApiUrl

# Load Syncthing API key
$config = Get-Content $ConfigPath | ConvertFrom-Json
$ApiKey = $config.gui.apikey

# Prepare headers
$Headers = @{ "X-API-Key" = $ApiKey }

# Supervisor fields
$ApiOK       = $false
$StatusOK    = $false
$MeshOK      = $false
$ActivationOK = $false

# Check API ping
try {
    $pong = Invoke-RestMethod -Uri "$ApiUrl/rest/system/ping" -Headers $Headers -Method Get
    if ($pong -eq "pong") { $ApiOK = $true }
} catch {}

# Check system status
try {
    Invoke-RestMethod -Uri "$ApiUrl/rest/system/status" -Headers $Headers -Method Get | Out-Null
    $StatusOK = $true
} catch {}

# Mesh health (LAN ping)
try {
    $LanIP = ($ApiUrl.Split("/")[2].Split(":")[0])
    $MeshOK = Test-Connection -ComputerName $LanIP -Count 1 -Quiet
} catch {}

# Activation status (read last activation result)
$ActivationFile = "C:\SemperFix\ConfigBackup\activation-status.json"
if (Test-Path $ActivationFile) {
    try {
        $activation = Get-Content $ActivationFile | ConvertFrom-Json
        $ActivationOK = $activation.Activation.ActivationOK
    } catch {}
}

# Build supervisor JSON
$result = [ordered]@{
    NodeRole      = $NodeRole
    ApiUrl        = $ApiUrl
    Supervisor    = @{
        ApiOK        = $ApiOK
        StatusOK     = $StatusOK
        MeshOK       = $MeshOK
        ActivationOK = $ActivationOK
        Timestamp    = (Get-Date).ToString("o")
    }
}

# Write to file
$result | ConvertTo-Json -Depth 10 | Set-Content $StatusPath

# Also print to stdout for debugging
$result | ConvertTo-Json -Depth 10
>>>>>>> 9f05a1b271981a50456b118fd05def3dd96a74f5
