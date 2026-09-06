<#
    phoenix-status-write.ps1
    Writes phoenix-status.json v2 using the authoritative API key source.
#>

param(
    [string]$StatusPath = "C:\SemperFix\ConfigBackup\phoenix-status.json",
    [string]$Role,
    [string]$Status,
    [string]$NodeName,
    [string]$MasterNode,
    [string]$SecondaryNode,
    [string]$Lineage,
    [hashtable]$SyncthingHealth,
    [hashtable]$PhoenixHealth,
    [hashtable]$Actions
)

# Load API key from SemperFix config (authoritative)
$Config = Get-Content "C:\SemperFix\Tools\semperfix-config.json" | ConvertFrom-Json
$ApiKey = $Config.ApiKey

$now = Get-Date

$doc = @{
    Role   = $Role
    Status = $Status

    Node = @{
        Name        = $NodeName
        LastUpdated = $now.ToString("o")
    }

    Cluster = @{
        MasterNode    = $MasterNode
        SecondaryNode = $SecondaryNode
        Lineage       = $Lineage
        LastFailover  = $null
        LastRecovery  = $null
    }

    Syncthing = $SyncthingHealth

    Health = $PhoenixHealth

    Actions = $Actions

    Meta = @{
        Version       = "2.0"
        GeneratedBy   = "phoenix-status-write"
        ApiKeySource  = "semperfix-config.json"
        Timestamp     = $now.ToString("o")
    }
}

$doc | ConvertTo-Json -Depth 8 | Set-Content -Path $StatusPath -Encoding UTF8
