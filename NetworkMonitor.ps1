$adapterName = "Wi-Fi" # Change to your adapter's name

function ConvertToLargestUnit {
    param($bytesPerSecond)

    if ($bytesPerSecond -gt 1MB) {
        return "{0:N2} MB/s" -f ($bytesPerSecond / 1MB)
    } elseif ($bytesPerSecond -gt 1KB) {
        return "{0:N2} KB/s" -f ($bytesPerSecond / 1KB)
    } else {
        return "{0} Bytes/s" -f $bytesPerSecond
    }
}

# Get initial statistics
$initialStats = Get-NetAdapterStatistics -Name $adapterName
$initialReceivedBytes = $initialStats.ReceivedBytes
$initialSentBytes = $initialStats.SentBytes
Start-Sleep -Seconds 1

while ($true) {
    # Get updated statistics
    $currentStats = Get-NetAdapterStatistics -Name $adapterName
    $currentReceivedBytes = $currentStats.ReceivedBytes
    $currentSentBytes = $currentStats.SentBytes

    # Calculate the difference to determine how many bytes were sent/received in the last second
    $downloadSpeed = $currentReceivedBytes - $initialReceivedBytes
    $uploadSpeed = $currentSentBytes - $initialSentBytes

    # Display the results in the desired format
    $downloadMetric = ConvertToLargestUnit -bytesPerSecond $downloadSpeed
    $uploadMetric = ConvertToLargestUnit -bytesPerSecond $uploadSpeed

    # Clear the current line and overwrite with new values
    Write-Host -NoNewline ("`rDownload: $downloadMetric | Upload: $uploadMetric" + (' ' * 10))

    # Set the current stats as the initial stats for the next iteration
    $initialReceivedBytes = $currentReceivedBytes
    $initialSentBytes = $currentSentBytes

    # Wait for a second before the next check
    Start-Sleep -Seconds 1
}