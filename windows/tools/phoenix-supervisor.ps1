<#
    phoenix-supervisor.ps1 (Syncthing Edition)
    Supervises Phoenix state using Syncthing and phoenix-status.json v2.
#>

param(
    [int]$IntervalSeconds = 30,
    [string]$StatusPath = "C:\SemperFix\ConfigBackup\phoenix-status.json",
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

function Acquire-Lock {
    param([string]$Path)
    try {
        $content = @{ pid = $PID; ts = (Get-Date).ToString("o") } | ConvertTo-Json
        Set-Content -Path $Path -Value $content -NoNewline -Encoding UTF8 -ErrorAction Stop
        return $true
    } catch { return $false }
}

function Release-Lock {
    param([string]$Path)
    if (Test-Path $Path) { Remove-Item $Path -Force -ErrorAction SilentlyContinue }
}

function Invoke-Script {
    param([string]$ScriptPath, [string[]]$Args)
    $proc = Start-Process -FilePath "powershell" -ArgumentList "-NoProfile","-ExecutionPolicy","Bypass","-File",$ScriptPath,$Args -Wait -PassThru -ErrorAction SilentlyContinue
    if ($proc) { return $proc.ExitCode } else { return 1 }
}

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
        }

        # 2. Load status
        if (-not (Test-Path $StatusPath)) {
            Write-Log "Status file missing at $StatusPath" "ERROR"
            Release-Lock -Path $LockPath
            Start-Sleep -Seconds ([math]::Min($backoff, $MaxBackoffSeconds))
            $backoff = [math]::Min($backoff * 2, $MaxBackoffSeconds)
            continue
        }

        $status = Get-Content -Raw -Path $StatusPath | ConvertFrom-Json
        $role   = $status.Role
        $state  = $status.Status

        Write-Log "Supervisor view: Role=$role Status=$state"

        $shouldPromote = $false
        $shouldDemote  = $false
        $shouldRecover = $false

        if ($role -eq "SECONDARY-PASSIVE" -and $state -eq "FAILOVER_ALLOWED" -and $health.Healthy) {
            $shouldPromote = $true
        }

        if ($role -eq "SECONDARY-ACTIVE" -and $state -eq "RECOVER" -and $health.Healthy) {
            $shouldRecover = $true
        }

        if ($role -eq "MASTERZERO-ACTIVE" -and $state -eq "DEGRADED" -and $health.Healthy) {
            $shouldDemote = $true
        }

        if ($shouldPromote) {
            Write-Log "Decision: promote this node to SECONDARY-ACTIVE."
            if ($Mode -eq "auto") {
                $rc = Invoke-Script -ScriptPath "C:\SemperFix\tools\phoenix-promote.ps1" -Args @()
                Write-Log "Promotion exit code: $rc"
            } else {
                Write-Log "Manual mode: promotion not executed."
            }
        } elseif ($shouldRecover) {
            Write-Log "Decision: recover MASTERZERO."
            if ($Mode -eq "auto") {
                $rc = Invoke-Script -ScriptPath "C:\SemperFix\tools\phoenix-recover.ps1" -Args @()
                Write-Log "Recovery exit code: $rc"
            } else {
                Write-Log "Manual mode: recovery not executed."
            }
        } elseif ($shouldDemote) {
            Write-Log "Decision: demote this node from ACTIVE."
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
