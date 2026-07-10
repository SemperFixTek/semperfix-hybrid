param(
    [string]$ConfigPath = "C:\SemperFix\Tools\semperfix-config.json"
)

$result = [ordered]@{
    NodeRole  = $null
    Timestamp = (Get-Date).ToString("o")
    Bootstrap = $null
    Handshake = $null
    Verify    = $null
    Errors    = @()
}

try {
    $result.Bootstrap = & "C:\SemperFix\Tools\mesh-bootstrap.ps1" -ConfigPath $ConfigPath | ConvertFrom-Json
}
catch {
    $result.Errors += "Bootstrap failed: $($_.Exception.Message)"
}

try {
    $result.Handshake = & "C:\SemperFix\Tools\mesh-handshake.ps1" -ConfigPath $ConfigPath | ConvertFrom-Json
}
catch {
    $result.Errors += "Handshake failed: $($_.Exception.Message)"
}

try {
    $result.Verify = & "C:\SemperFix\Tools\mesh-verify.ps1" -ConfigPath $ConfigPath | ConvertFrom-Json
}
catch {
    $result.Errors += "Verify failed: $($_.Exception.Message)"
}

$result.NodeRole = $result.Bootstrap.NodeRole

$result | ConvertTo-Json -Depth 6
