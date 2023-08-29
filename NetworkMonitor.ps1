<#
.SYNOPSIS
    This PowerShell script monitors the upload and download speeds of a network adapter.

.DESCRIPTION
    The script continuously fetches network statistics from a specified network adapter and calculates the current upload and download speeds. It outputs these speeds in a human-readable format (Bytes/s, KB/s, or MB/s) in the console window. The default adapter is set to "Wi-Fi", but this can be overridden with the `-adapterName` parameter.

.PARAMETER adapterName
    The name of the network adapter to monitor. Defaults to "Wi-Fi".

.EXAMPLE
    .\NetworkMonitor.ps1
    Monitors the "Wi-Fi" adapter's network statistics and displays the upload and download speeds.

.EXAMPLE
    .\NetworkMonitor.ps1 -adapterName "Ethernet"
    Monitors the "Ethernet" adapter's network statistics and displays the upload and download speeds.
#>

param (
    [string]$adapterName = "Wi-Fi"
)

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