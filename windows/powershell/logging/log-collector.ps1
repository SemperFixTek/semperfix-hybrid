param(
    [string]$OutputPath = "C:\SemperFix\Logs"
)

# Ensure output directory exists
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath | Out-Null
}

$timestamp = (Get-Date).ToString("yyyy-MM-dd_HH-mm-ss")
$logBundle = Join-Path $OutputPath "SemperFixLogs_$timestamp"

New-Item -ItemType Directory -Path $logBundle | Out-Null

# Windows logs
$windowsLogs = @(
    "C:\SemperFix\Tools\phoenix-dryrun.log",
    "C:\SemperFix\Tools\mesh-bootstrap.log",
    "C:\SemperFix\Tools\mesh-handshake.log",
    "C:\SemperFix\Tools\mesh-verify.log",
    "C:\SemperFix\Tools\mesh-activate.log"
)

foreach ($log in $windowsLogs) {
    if (Test-Path $log) {
        Copy-Item $log -Destination $logBundle -ErrorAction SilentlyContinue
    }
}

# WSL logs
try {
    wsl.exe -- bash -c "cp /opt/semperfix/logs/* /mnt/c/SemperFix/Logs/$timestamp/" 2>$null
}
catch {
    # WSL may not exist in Golden Template state — suppress
}

Write-Output "Logs collected at $logBundle"
