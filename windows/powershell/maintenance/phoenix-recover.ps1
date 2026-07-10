param(
    [string]$NodeRole
)

$result = [ordered]@{
    NodeRole  = $NodeRole
    Timestamp = (Get-Date).ToString("o")
    Message   = "Recovery placeholder executed."
}

$result | ConvertTo-Json -Depth 6
