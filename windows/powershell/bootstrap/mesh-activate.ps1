param(
    [string]$ConfigPath = "C:\SemperFix\Tools\semperfix-config.json"
)

& "C:\SemperFix\Tools\mesh-bootstrap.ps1" -ConfigPath $ConfigPath | Out-Null
& "C:\SemperFix\Tools\mesh-handshake.ps1" -ConfigPath $ConfigPath | Out-Null
& "C:\SemperFix\Tools\mesh-verify.ps1" -ConfigPath $ConfigPath | Out-Null
