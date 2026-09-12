# Phoenix v2 — Windows Mesh Activation
$ErrorActionPreference = "Stop"

$configPath = "C:\SemperFix\ConfigBackup\phoenix.json"
$config = Get-Content $configPath | ConvertFrom-Json

$NodeRole = $config.NodeRole
$ApiUrl   = $config.ApiUrl

$bootstrap = powershell -File "C:\SemperFix\Tools\mesh-bootstrap.ps1" | ConvertFrom-Json
$status    = powershell -File "C:\SemperFix\Tools\mesh-status.ps1"    | ConvertFrom-Json
$verify    = powershell -File "C:\SemperFix\Tools\mesh-verify.ps1"    | ConvertFrom-Json

$ActivationOK =
    $bootstrap.BootstrapOK -and
    $status.Status.IdentityOK -and
    $status.Status.EndpointOK -and
    $verify.VerifyOK

$result = [ordered]@{
    NodeRole   = $NodeRole
    ApiUrl     = $ApiUrl
    Activation = @{
        Bootstrap    = $bootstrap
        Status       = $status
        Verify       = $verify
        ActivationOK = $ActivationOK
        Timestamp    = (Get-Date).ToString("o")
    }
}

$result | ConvertTo-Json -Depth 10
