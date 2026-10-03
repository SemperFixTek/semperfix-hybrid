# Phoenix QUIC Responder (Windows)
# Responds "ack" to any UDP packet received on port 22000.

$port = 22000
$udp = New-Object System.Net.Sockets.UdpClient($port)
$encoding = [System.Text.Encoding]::ASCII

Write-Host "[Phoenix-Responder] Listening on UDP port $port..."

while ($true) {
    try {
        # Receive packet
        $remoteEP = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Any, 0)
        $data = $udp.Receive([ref]$remoteEP)
        $msg = $encoding.GetString($data)

        # Log inbound packet
        $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        Write-Host "[$timestamp] Probe received from $($remoteEP.Address):$($remoteEP.Port) — '$msg'"

        # Send ACK
        $ack = $encoding.GetBytes("ack")
        $udp.Send($ack, $ack.Length, $remoteEP)

        Write-Host "[$timestamp] ACK sent to $($remoteEP.Address):$($remoteEP.Port)"
    }
    catch {
        $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        Write-Host "[$timestamp] Error: $($_.Exception.Message)"
    }
}
