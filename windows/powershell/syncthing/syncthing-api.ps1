param(
    [Parameter(Mandatory=$true)]
    [string]$ApiKey,

    [Parameter(Mandatory=$true)]
    [string]$BaseUrl
)

function Invoke-SyncthingApi {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )

    $headers = @{ "X-API-Key" = $ApiKey }
    $url = "$BaseUrl$Path"

    try {
        return Invoke-RestMethod -Uri $url -Headers $headers -Method Get -ErrorAction Stop
    }
    catch {
        throw "Syncthing API call failed: $($_.Exception.Message)"
    }
}
