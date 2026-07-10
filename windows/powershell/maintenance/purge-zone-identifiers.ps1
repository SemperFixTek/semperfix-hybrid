<#
    SemperFix Zone Identifier Purge Script
    Removes all NTFS Alternate Data Streams named "Zone.Identifier"
    Safe for Golden Template, MASTERZERO, SECONDARY, OFFSITE
#>

param(
    [string]$TargetPath = "C:\SemperFix",
    [switch]$Recurse
)

Write-Host "=== SemperFix Zone Identifier Purge ==="
Write-Host "Target: $TargetPath"
Write-Host ""

if (-not (Test-Path $TargetPath)) {
    Write-Host "ERROR: Target path does not exist."
    exit 1
}

# Collect files
$files = Get-ChildItem -Path $TargetPath -File -Recurse:$Recurse -ErrorAction SilentlyContinue

$removed = 0
$checked = 0

foreach ($file in $files) {
    $checked++

    try {
        # Check for ADS stream
        $streams = Get-Item -Path $file.FullName -Stream * -ErrorAction SilentlyContinue

        foreach ($stream in $streams) {
            if ($stream.Stream -eq "Zone.Identifier") {
                Write-Host "Removing Zone.Identifier from: $($file.FullName)"
                Remove-Item -Path $file.FullName -Stream "Zone.Identifier" -ErrorAction SilentlyContinue
                $removed++
            }
        }
    }
    catch {
        Write-Host "Error checking $($file.FullName): $($_.Exception.Message)"
    }
}

Write-Host ""
Write-Host "=== Purge Complete ==="
Write-Host "Files checked: $checked"
Write-Host "Zone.Identifier streams removed: $removed"
Write-Host ""
Write-Host "SemperFix filesystem is now ADS-clean."
