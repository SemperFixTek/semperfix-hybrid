& "C:\SemperFix\Tools\phoenix-role-check.ps1" | Out-Null
& "C:\SemperFix\Tools\phoenix-escalate.ps1" -Reason "Dry-run test" -Stage "dryrun" | Out-Null
& "C:\SemperFix\Tools\phoenix-failover.ps1" -DryRun | Out-Null
