<#
    phoenix-syncthing-health.ps1 (Unified Config Edition)
    Provides a function phoenix-syncthing-health for supervisor compatibility.
#>

param(
    [string]$PhoenixPath = "C:\SemperFix\ConfigBackup\phoenix.json"
)

function phoenix-syncthing-health {
    param(
        [string]$PhoenixPathInner = "C:\SemperFix\ConfigBackup\phoenix.json"
    )

    if (-not (Test-Path $PhoenixPathInner)) {
        return @{
            Healthy = $false
            Reason  = "phoenix.json missing"
            Status  = $null
        }
    }

    $phoenix = Get-Content -Raw -Path $PhoenixPathInner | ConvertFrom-Json

    # Determine local node
    $localNode = $phoenix.Nodes | Where-Object { $_.Name -eq $phoenix.NodeRole }

    if (-not $localNode) {
        return @{
            Healthy = $false
            Reason  = "Local node not found in phoenix.json"
            Status  = $null
        }
    }

    try {
        $resp = Invoke-RestMethod -Uri "$($localNode.ApiUrl)/rest/system/status" `
                                  -Headers @{ "X-API-Key" = $localNode.ApiKey }

        return @{
            Healthy = $true
            Reason  = "OK"
            Status  = $resp
        }
    }
    catch {
        return @{
            Healthy = $false
            Reason  = $_.Exception.Message
            Status  = $null
        }
    }
}

# If script is run directly, update phoenix.json
$health = phoenix-syncthing-health -PhoenixPathInner $PhoenixPath
$phoenix = Get-Content -Raw -Path $PhoenixPath | ConvertFrom-Json
$now = Get-Date

$phoenix.Syncthing = $health
$phoenix.Phoenix.LastUpdate = $now.ToString("o")

$phoenix | ConvertTo-Json -Depth 8 | Set-Content -Path $PhoenixPath -Encoding UTF8

Write-Host "Syncthing health updated."
