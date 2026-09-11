<#
 Phoenix v2 Supervisor
 Cluster-level coordinator
 Runs on all nodes, but ONLY ACTIVE node writes phoenix.cluster.json
 Reads:
   - phoenix.masterzero.json
   - phoenix.secondary.json
   - phoenix.offsite.json
 Writes:
   - phoenix.cluster.json (ACTIVE node only)
#>

Set-Location "C:\SemperFix\Tools"

$PhoenixRoot = "C:\SemperFix\ConfigBackup"

# Node-local files
$NodeFiles = @{
    "MASTERZERO" = "$PhoenixRoot\phoenix.masterzero.json"
    "SECONDARY"  = "$PhoenixRoot\phoenix.secondary.json"
    "OFFSITE"    = "$PhoenixRoot\phoenix.offsite.json"
}

# Cluster file
$ClusterFile = "$PhoenixRoot\phoenix.cluster.json"

function Load-NodeState {
    param($role)

    $path = $NodeFiles[$role]
    if (Test-Path $path) {
        return Get-Content $path -Raw | ConvertFrom-Json
    }
    else {
        Write-Warning "[SUPERVISOR] Missing node-local file for $role"
        return $null
    }
}

while ($true) {

    # ------------------------------------------------------------
    # LOAD ALL NODE-LOCAL STATES
    # ------------------------------------------------------------
    $masterzero = Load-NodeState "MASTERZERO"
    $secondary  = Load-NodeState "SECONDARY"
    $offsite    = Load-NodeState "OFFSITE"

    if (-not $masterzero -or -not $secondary -or -not $offsite) {
        Write-Warning "[SUPERVISOR] One or more node-local files missing."
        Start-Sleep -Seconds 10
        continue
    }

    # ------------------------------------------------------------
    # DETERMINE ACTIVE NODE (based on lineage + health)
    # ------------------------------------------------------------
    $lineage = $masterzero.Phoenix.Lineage  # lineage always stored in MASTERZERO file

    $masterHealthy   = $masterzero.Syncthing.Healthy
    $secondaryHealthy = $secondary.Syncthing.Healthy

    $activeNode = $null

    if ($lineage -eq "MASTERZERO" -and $masterHealthy) {
        $activeNode = "MASTERZERO"
    }
    elseif ($lineage -eq "MASTERZERO" -and -not $masterHealthy -and $secondaryHealthy) {
        # Failover condition
        $activeNode = "SECONDARY"
        $lineage = "SECONDARY"
    }
    elseif ($lineage -eq "SECONDARY" -and $secondaryHealthy) {
        $activeNode = "SECONDARY"
    }
    elseif ($lineage -eq "SECONDARY" -and -not $secondaryHealthy -and $masterHealthy) {
        # Recovery condition
        $activeNode = "MASTERZERO"
        $lineage = "MASTERZERO"
    }
    else {
        # Worst case: both unhealthy → MASTERZERO remains lineage
        $activeNode = "MASTERZERO"
    }

    Write-Host "[SUPERVISOR] ActiveNode=$activeNode Lineage=$lineage"

    # ------------------------------------------------------------
    # BUILD CLUSTER STATE (but only write if THIS node is ACTIVE)
    # ------------------------------------------------------------
    $cluster = [ordered]@{
        ClusterName = "SemperFix-Hybrid"
        MasterNode  = "MASTERZERO"

        Nodes = $masterzero.Nodes

        Phoenix = @{
            Version   = "2.0.0"
            Lineage   = $lineage
            Timestamp = (Get-Date).ToString("o")
        }

        Status = @{
            Role             = "$activeNode-ACTIVE"
            State            = ($activeNode -eq "MASTERZERO" ? $masterzero.Status.State : $secondary.Status.State)
            EscalationReason = $null
            Message          = "Cluster state updated by $activeNode supervisor."
            Timestamp        = (Get-Date).ToString("o")
        }

        Syncthing = @{
            MASTERZERO = @{
                Healthy = $masterzero.Syncthing.Healthy
                Reason  = $masterzero.Syncthing.Reason
            }
            SECONDARY = @{
                Healthy = $secondary.Syncthing.Healthy
                Reason  = $secondary.Syncthing.Reason
            }
            OFFSITE = @{
                Healthy = $offsite.Syncthing.Healthy
                Reason  = $offsite.Syncthing.Reason
            }
        }

        Actions = @{
            LastAction = "SupervisorUpdate"
            History    = @()
        }
    }

    # ------------------------------------------------------------
    # WRITE CLUSTER FILE ONLY IF THIS NODE IS ACTIVE
    # ------------------------------------------------------------
    $thisNodeRole = $masterzero.NodeRole  # this script runs on MASTERZERO or SECONDARY or OFFSITE

    if ($thisNodeRole -eq $activeNode) {
        Write-Host "[SUPERVISOR] Writing cluster state (phoenix.cluster.json)"
        $cluster | ConvertTo-Json -Depth 8 | Set-Content $ClusterFile -Encoding UTF8
    }
    else {
        Write-Host "[SUPERVISOR] This node is not ACTIVE → cluster.json not written."
    }

    Start-Sleep -Seconds 10
}
