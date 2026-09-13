<#
    phoenix-status-write.ps1 (Unified Config Edition)
    Writes Phoenix status/state into phoenix.json.
#>

<<<<<<< HEAD
$configPath  = "C:\SemperFix\ConfigBackup\phoenix.json"
$statusPath  = "C:\SemperFix\ConfigBackup\phoenix-status.json"

$config = Get-Content $configPath | ConvertFrom-Json

$ApiUrl = $config.ApiUrl
$ApiKey = $config.ApiKey

$Headers = @{ "X-API-Key" = $ApiKey }

$ApiOK    = $false
$StatusOK = $false

try {
    $pong = Invoke-RestMethod "$ApiUrl/rest/system/ping" -Headers $Headers
    if ($pong.ping -eq "pong") { $ApiOK = $true }
} catch {}

try {
    $status = Invoke-RestMethod "$ApiUrl/rest/system/status" -Headers $Headers
    if ($status.myID) { $StatusOK = $true }
} catch {}

$result = [ordered]@{
    ApiOK     = $ApiOK
    StatusOK  = $StatusOK
    ApiUrl    = $ApiUrl
    Timestamp = (Get-Date).ToString("o")
}

$result | ConvertTo-Json -Depth 10 | Set-Content $statusPath
$result | ConvertTo-Json -Depth 10
=======
param(
    [string]$PhoenixPath = "C:\SemperFix\ConfigBackup\phoenix.json",
    [string]$Role,
    [string]$State,
    [string]$Lineage,
    [hashtable]$SyncthingHealth,
    [hashtable]$PhoenixHealth,
    [hashtable]$Actions,
    [string]$EscalationReason = $null,
    [string]$Message = "Phoenix status updated."
)

if (-not (Test-Path $PhoenixPath)) {
    Write-Host "ERROR: phoenix.json missing at $PhoenixPath"
    exit 1
}

$phoenix = Get-Content -Raw -Path $PhoenixPath | ConvertFrom-Json
$now = Get-Date

# Update core Phoenix block
if (-not $phoenix.Phoenix) {
    $phoenix | Add-Member -MemberType NoteProperty -Name Phoenix -Value (@{})
}

$phoenix.Phoenix.Version    = $phoenix.Phoenix.Version
$phoenix.Phoenix.LastUpdate = $now.ToString("o")
$phoenix.Phoenix.Lineage    = $Lineage

# Update status block
if (-not $phoenix.Status) {
    $phoenix | Add-Member -MemberType NoteProperty -Name Status -Value (@{})
}

$phoenix.Status.Role             = $Role
$phoenix.Status.State            = $State
$phoenix.Status.EscalationReason = $EscalationReason
$phoenix.Status.Timestamp        = $now.ToString("o")
$phoenix.Status.Message          = $Message

# Attach health + actions
$phoenix.Syncthing = $SyncthingHealth
$phoenix.Health    = $PhoenixHealth
$phoenix.Actions   = $Actions

# Persist
$phoenix | ConvertTo-Json -Depth 8 | Set-Content -Path $PhoenixPath -Encoding UTF8

Write-Host "phoenix.json status write OK."
exit 0
>>>>>>> f421cc4430b14bddcd9923ad4fd6c0755ddc7b40
