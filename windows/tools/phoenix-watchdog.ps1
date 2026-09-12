<#
 Phoenix v2 Watchdog
 Node-local writer
 Runs on MASTERZERO, SECONDARY, OFFSITE
 Writes ONLY phoenix.<node>.json
 Never writes phoenix.cluster.json
#>

Set-Location "C:\SemperFix\Tools"

# Determine which node-local file to load based on NodeRole inside the file
$PhoenixRoot = "C:\SemperFix\ConfigBackup"
$LocalFiles = @{
    "MASTERZERO" = "$PhoenixRoot\phoenix.masterzero.json"
    "SECONDARY"  = "$PhoenixRoot\phoenix.secondary.json"
    "OFFSITE"    = "$PhoenixRoot\phoenix.offsite.json"
}

while ($true) {

    # Load node-local phoenix file
    $localPhoenix = $null
    foreach ($file in $LocalFiles.Values) {
        if (Test-Path $file) {
            $candidate = Get-Content $file -Raw | ConvertFrom-Json
            if ($candidate.NodeRole -and $LocalFiles.ContainsKey($candidate.NodeRole)) {
                $localPhoenix = $candidate
                $PhoenixPath = $file
                break
            }
        }
    }

    if (-not $localPhoenix) {
        Write-Warning "[WATCHDOG] No valid node-local phoenix file found."
        Start-Sleep -Seconds 5
        continue
    }

    $nodeRole = $localPhoenix.NodeRole
    $nodes    = $localPhoenix.Nodes

    # Identify THIS node's entry in Nodes[]
    $nodeEntry = $nodes | Where-Object { $_.Name -eq $nodeRole }

    if (-not $nodeEntry) {
        Write-Warning "[WATCHDOG] No Nodes[] entry found for $nodeRole."
        Start-Sleep -Seconds 5
        continue
    }

    # Build Syncthing API endpoint
    $apiUrl = $nodeEntry.ApiUrl
    $pingUrl = "$apiUrl/rest/system/ping"

    # ------------------------------------------------------------
    # SYNCTHING HEALTH CHECK
    # ------------------------------------------------------------
    try {
        $pong = Invoke-RestMethod -Uri $pingUrl -TimeoutSec 3
        $healthy = ($pong -eq "pong")
        $reason = $null
    }
    catch {
        $healthy = $false
        $reason = $_.Exception.Message
    }

    # Update node-local Syncthing health
    $localPhoenix.Syncthing.Healthy = $healthy
    $localPhoenix.Syncthing.Reason  = $reason
    $localPhoenix.Phoenix.Timestamp = (Get-Date).ToString("o")

    Write-Host "[WATCHDOG] Node=$nodeRole Healthy=$healthy Reason=$reason"

    # ------------------------------------------------------------
    # NODE-LOCAL ROLE LOGIC
    # ------------------------------------------------------------

    switch ($nodeRole) {

        "MASTERZERO" {
            if ($healthy) {
                # MASTERZERO must always reclaim ACTIVE when healthy
                $localPhoenix.Status.Role  = "MASTERZERO-ACTIVE"
                $localPhoenix.Status.State = "HEALTHY"
                $localPhoenix.Status.Message = "MASTERZERO healthy; ACTIVE role enforced."
                $localPhoenix.Phoenix.Lineage = "MASTERZERO"
            }
            else {
                $localPhoenix.Status.State = "DEGRADED"
                $localPhoenix.Status.Message = "MASTERZERO unhealthy; DEGRADED."
            }
        }

        "SECONDARY" {
            if ($healthy -and $localPhoenix.Phoenix.Lineage -eq "MASTERZERO") {
                # MASTERZERO healthy → SECONDARY must be PASSIVE
                $localPhoenix.Status.Role  = "SECONDARY-PASSIVE"
                $localPhoenix.Status.State = "HEALTHY"
                $localPhoenix.Status.Message = "SECONDARY healthy; MASTERZERO lineage; PASSIVE."
            }
            elseif (-not $healthy) {
                # SECONDARY unhealthy → DEGRADED
                $localPhoenix.Status.State = "DEGRADED"
                $localPhoenix.Status.Message = "SECONDARY unhealthy; DEGRADED."
            }
        }

        "OFFSITE" {
            # OFFSITE never promotes or demotes
            $localPhoenix.Status.Role  = "OFFSITE-PASSIVE"
            $localPhoenix.Status.State = $healthy ? "HEALTHY" : "DEGRADED"
            $localPhoenix.Status.Message = "OFFSITE observer mode."
        }
    }

    # ------------------------------------------------------------
    # WRITE NODE-LOCAL FILE
    # ------------------------------------------------------------
    $localPhoenix.Status.Timestamp = (Get-Date).ToString("o")
    $localPhoenix | ConvertTo-Json -Depth 8 | Set-Content $PhoenixPath -Encoding UTF8

    Start-Sleep -Seconds 5
}
