<#
    phoenix-status-write.ps1
    Writes phoenix-status.json v2 in a consistent format.
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

$now = Get-Date

$doc = @{
    Role   = $Role
    Status = $Status

    Node = @{
        Name        = $NodeName
        LastUpdated = $now.ToString("o")
    }

    Cluster = @{
        MasterNode   = $MasterNode
        SecondaryNode = $SecondaryNode
        Lineage      = $Lineage
        LastFailover = $null
        LastRecovery = $null
    }

    Syncthing = $SyncthingHealth

    Health = $PhoenixHealth

    Actions = $Actions

    Meta = @{
        Version     = "2.0"
        GeneratedBy = "phoenix-status-write"
        Timestamp   = $now.ToString("o")
    }
}

$doc | ConvertTo-Json -Depth 8 | Set-Content -Path $StatusPath -Encoding UTF8
