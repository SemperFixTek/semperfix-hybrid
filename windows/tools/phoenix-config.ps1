# Phoenix Global Configuration Loader

# Define the config path ONCE
$Global:PhoenixConfigPath = "C:\SemperFix\tools\semperfix-config.json"

# Load the JSON
try {
    $Global:PhoenixConfig = Get-Content $Global:PhoenixConfigPath | ConvertFrom-Json
}
catch {
    $Global:PhoenixConfig = $null
}
