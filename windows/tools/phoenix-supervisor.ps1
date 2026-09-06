<#
phoenix-supervisor.ps1 (Syncthing Transport)
Runs continuously (or scheduled) to supervise Phoenix state.
Usage:
  powershell -File C:\SemperFix\tools\phoenix-supervisor.ps1 -IntervalSeconds 30 -Mode auto
#>

param(
    [int]$IntervalSeconds = 30,
    [string]$ConfigPath = "C:\SemperFix\tools\phoenix.json",
    [string]$LocalStatusPath = "C:\SemperFix\ConfigBackup\phoenix-status.json",
    [string]$LockPath = "C:\SemperFix\ConfigBackup\phoenix-supervisor.lock",
    [string]$LogPath = "C:\SemperFix\Logs\phoenix-supervisor.log",
    [ValidateSet("auto","manual")] [string]$Mode = "auto",
    [int]$MaxBackoffSeconds = 300
)

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$ts] [$Level] $Message"
    $line | Out-File -FilePath $LogPath -Append -Encoding UTF8
    Write-Host $line
}

# dot-source syncthing health module
. "C:\SemperFix\tools\phoenix-syncthing-health.ps1"

Write-Log "Phoenix supervisor starting in $Mode mode. Interval ${IntervalSeconds}s."

$backoff = 1
while ($true) {
    if (-not (Acquire-Lock -Path $LockPath)) {
        Write-Log "Lock exists. Another supervisor may be running. Sleeping $IntervalSeconds seconds." "WARN"
        Start-Sleep -Seconds $IntervalSeconds
        continue
    }

    try {
        # 1. Syncthing health
        $health = phoenix-syncthing-health
        if (-not $health.Healthy) {
            Write-Log "Syncthing health degraded: $($health.Reason)" "WARN"
            # optional: escalate here
        }

        # 2. Verify local status
        if (-not (Test-Path $LocalStatusPath)) {
            Write-Log "Local Phoenix status missing at $LocalStatusPath" "ERROR"
            Release-Lock -Path $LockPath
            Start-Sleep -Seconds ([math]::Min($backoff, $MaxBackoffSeconds))
            $backoff = [math]::Min($backoff * 2, $MaxBackoffSeconds)
            continue
        }

        $local = Get-Content -Raw -Path $LocalStatusPath | ConvertFrom-Json

        $role   = $local.Role
        $status = $local.Status

        Write-Log "Supervisor view: Role=$role Status=$status"

        $shouldPromote = $false
        $shouldDemote  = $false

        # Example decision logic (simplified for Syncthing):
        if ($role -eq "SECONDARY-PASSIVE" -and $status -eq "FAILOVER_ALLOWED" -and $health.Healthy) {
            $shouldPromote = $true
        }

        if ($role -eq "SECONDARY-ACTIVE" -and $status -eq "RECOVER" -and $health.Healthy) {
            $shouldDemote = $true
        }

        if ($shouldPromote) {
            Write-Log "Decision: promote this node to ACTIVE."
            if ($Mode -eq "auto") {
                $rc = Invoke-Script -ScriptPath "C:\SemperFix\tools\phoenix-promote.ps1" -Args @()
                Write-Log "Promotion exit code: $rc"
            } else {
                Write-Log "Manual mode: promotion not executed."
            }
        } elseif ($shouldDemote) {
            Write-Log "Decision: demote this node to PASSIVE / allow MASTERZERO recovery."
            if ($Mode -eq "auto") {
                $rc = Invoke-Script -ScriptPath "C:\SemperFix\tools\phoenix-demote.ps1" -Args @()
                Write-Log "Demotion exit code: $rc"
            } else {
                Write-Log "Manual mode: demotion not executed."
            }
        } else {
            Write-Log "No role change required."
        }

        $backoff = 1
    }
    catch {
        Write-Log "Supervisor loop exception: $($_.Exception.Message)" "ERROR"
    }
    finally {
        Release-Lock -Path $LockPath
    }

    Start-Sleep -Seconds $IntervalSeconds
}
