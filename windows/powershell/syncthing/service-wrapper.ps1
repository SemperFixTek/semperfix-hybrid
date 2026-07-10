param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("start","stop","restart","status")]
    [string]$Action
)

function Get-SyncthingStatus {
    try {
        $svc = Get-Service -Name "syncthing" -ErrorAction Stop
        return $svc.Status
    }
    catch {
        return "NotInstalled"
    }
}

switch ($Action) {

    "start" {
        if (Get-SyncthingStatus -eq "Running") {
            Write-Output "Syncthing already running."
        } else {
            Start-Service -Name "syncthing"
            Write-Output "Syncthing started."
        }
    }

    "stop" {
        if (Get-SyncthingStatus -eq "Stopped") {
            Write-Output "Syncthing already stopped."
        } else {
            Stop-Service -Name "syncthing"
            Write-Output "Syncthing stopped."
        }
    }

    "restart" {
        Restart-Service -Name "syncthing"
        Write-Output "Syncthing restarted."
    }

    "status" {
        Write-Output ("Syncthing status: " + (Get-SyncthingStatus))
    }
}
