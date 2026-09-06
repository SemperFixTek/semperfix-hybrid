<#
phoenix-supervisor.ps1
Runs continuously (or scheduled) to supervise Phoenix state.
Usage:
  powershell -File C:\SemperFix\tools\phoenix-supervisor.ps1 -IntervalSeconds 30 -Mode auto
Modes:
  auto  - allow automatic promote/demote
  manual - only log decisions, do not change config
#>

param(
    [int]$IntervalSeconds = 30,
    [string]$ConfigPath = "C:\SemperFix\tools\phoenix.json",
    [string]$LocalStatusPath = "C:\SemperFix\Config\phoenix-status.json",
    [string]$RemoteStatusPath = "\\SECONDARY\SemperFix\Config\phoenix-status.json",
    [string]$LockPath = "C:\SemperFix\Config\phoenix-supervisor.lock",
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

function Acquire-Lock {
    param([string]$Path)
    try {
        $now = Get-Date
        $content = @{ pid = $PID; ts = $now.ToString("o") } | ConvertTo-Json
        Set-Content -Path $Path -Value $content -NoNewline -Encoding UTF8 -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

function Release-Lock {
    param([string]$Path)
    if (Test-Path $Path) { Remove-Item $Path -Force -ErrorAction SilentlyContinue }
}

function Run-CommandSafe {
    param([scriptblock]$Script)
    try {
        & $Script
        return @{ Success = $true }
    } catch {
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

# helper to call existing scripts and return exit code
function Invoke-Script {
    param([string]$ScriptPath, [string[]]$Args)
    $cmd = "powershell -NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`" $($Args -join ' ')"
    Write-Log "Invoking: $cmd"
    $proc = Start-Process -FilePath "powershell" -ArgumentList "-NoProfile","-ExecutionPolicy","Bypass","-File",$ScriptPath,$Args -Wait -PassThru -ErrorAction SilentlyContinue
    if ($proc) { return $proc.ExitCode } else { return 1 }
}

# main loop
Write-Log "Phoenix supervisor starting in $Mode mode. Interval ${IntervalSeconds}s."

$backoff = 1
while ($true) {
    if (-not (Acquire-Lock -Path $LockPath)) {
        Write-Log "Lock exists. Another supervisor may be running. Sleeping $IntervalSeconds seconds." "WARN"
        Start-Sleep -Seconds $IntervalSeconds
        continue
    }

    try {
        # 1. Bootstrap local model
        $rc = Invoke-Script -ScriptPath "C:\SemperFix\tools\phoenix-bootstrap.ps1" -Args @()
        if ($rc -ne 0) {
            Write-Log "Bootstrap failed with exit $rc" "ERROR"
            Release-Lock -Path $LockPath
            Start-Sleep -Seconds ([math]::Min($backoff, $MaxBackoffSeconds))
            $backoff = [math]::Min($backoff * 2, $MaxBackoffSeconds)
            continue
        }

        # 2. Handshake with peer
        $rc = Invoke-Script -ScriptPath "C:\SemperFix\tools\phoenix-handshake.ps1" -Args @("-LocalStatusPath","`"$LocalStatusPath`"","-RemoteStatusPath","`"$RemoteStatusPath`"")
        if ($rc -ne 0) {
            Write-Log "Handshake failed with exit $rc" "WARN"
            Release-Lock -Path $LockPath
            Start-Sleep -Seconds ([math]::Min($backoff, $MaxBackoffSeconds))
            $backoff = [math]::Min($backoff * 2, $MaxBackoffSeconds)
            continue
        }

        # 3. Verify local status
        $rc = Invoke-Script -ScriptPath "C:\SemperFix\tools\phoenix-verify.ps1" -Args @("-StatusPath","`"$LocalStatusPath`"")
        if ($rc -ne 0) {
            Write-Log "Verify failed with exit $rc" "WARN"
            # verify failure is not necessarily fatal; continue to decision logic
        }

        # 4. Load status files for decision making
        $local = Get-Content -Raw -Path $LocalStatusPath | ConvertFrom-Json
        $remote = $null
        try { $remote = Get-Content -Raw -Path $RemoteStatusPath | ConvertFrom-Json } catch { Write-Log "Unable to read remote status: $($_.Exception.Message)" "WARN" }

        # 5. Decision logic
        $currentMaster = $local.MasterNode
        $thisNode = $local.NodeRole
        # find node entries
        $localMasterEntry = $local.Nodes | Where-Object { $_.Name -eq $currentMaster }
        $localSelfEntry = $local.Nodes | Where-Object { $_.Name -eq $env:COMPUTERNAME -or $_.Name -eq $local.NodeRole -or $_.Name -eq $local.PhoenixMeta.Lineage } # best-effort match

        # Determine reachability
        $masterReachable = $false
        if ($localMasterEntry) { $masterReachable = $localMasterEntry.Reachable }

        # If master unreachable and this node is secondary and peer is healthy -> promote
        $shouldPromote = $false
        if ($local.NodeRole -eq "SECONDARY" -and -not $masterReachable) {
            # check remote health
            $peerHealthy = $false
            if ($remote) {
                $peerEntry = $remote.Nodes | Where-Object { $_.Name -ne $currentMaster }
                if ($peerEntry -and $peerEntry.Reachable) { $peerHealthy = $true }
            } else {
                # fallback to local view of other node
                $other = $local.Nodes | Where-Object { $_.Name -ne $currentMaster }
                if ($other -and $other.Reachable) { $peerHealthy = $true }
            }

            if ($peerHealthy) { $shouldPromote = $true }
        }

        # If this node is master and old master returned healthy -> demote
        $shouldDemote = $false
        if ($local.NodeRole -eq "MASTERZERO" -and $local.PhoenixMeta.Lineage) {
            $oldMaster = $local.PhoenixMeta.Lineage
            $oldEntry = $local.Nodes | Where-Object { $_.Name -eq $oldMaster }
            if ($oldEntry -and $oldEntry.Reachable -and $oldMaster -ne $currentMaster) {
                $shouldDemote = $true
            }
        }

        # 6. Act based on decisions
        if ($shouldPromote) {
            Write-Log "Decision: promote this node to master."
            if ($Mode -eq "auto") {
                $rc = Invoke-Script -ScriptPath "C:\SemperFix\tools\phoenix-promote.ps1" -Args @("-StatusPath","`"$LocalStatusPath`"","-ConfigPath","`"$ConfigPath`"")
                if ($rc -eq 0) {
                    Write-Log "Promotion executed successfully."
                } else {
                    Write-Log "Promotion script failed with exit $rc" "ERROR"
                }
            } else {
                Write-Log "Manual mode: promotion not executed."
            }
        } elseif ($shouldDemote) {
            Write-Log "Decision: demote old master back to secondary."
            if ($Mode -eq "auto") {
                $rc = Invoke-Script -ScriptPath "C:\SemperFix\tools\phoenix-demote.ps1" -Args @("-StatusPath","`"$LocalStatusPath`"","-ConfigPath","`"$ConfigPath`"")
                if ($rc -eq 0) {
                    Write-Log "Demotion executed successfully."
                } else {
                    Write-Log "Demotion script failed with exit $rc" "ERROR"
                }
            } else {
                Write-Log "Manual mode: demotion not executed."
            }
        } else {
            Write-Log "No role change required."
        }

        # reset backoff on success
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
