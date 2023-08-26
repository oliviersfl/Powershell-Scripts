<#
.SYNOPSIS
    This script continuously monitors and displays the upload and download speeds of the active network adapter.
.DESCRIPTION
    The script performs the following tasks:
    1. Dynamically identifies the first active network adapter on the machine.
    2. Measures the real-time upload and download speeds in bytes per second.
    3. Converts the speed into the most appropriate unit (MB/s, KB/s, or B/s) for easy reading.
    4. Updates the console output continuously with the latest speed metrics.
    5. Utilizes ANSI color codes for better visual distinction between upload and download metrics.
.NOTES
    Author: Olivier Sin Fai Lam
#>

# Function to clear the current line in the console
function Clear-CurrentLine {
    Write-Host "`r                                                                                     `r" -NoNewline
}

# Function to calculate the highest fitting unit
function Calculate-HighestUnit ($bytesPerSec) {
    $speedInKbps = $bytesPerSec / 1KB
    $speedInMbps = $speedInKbps / 1KB

    if ($speedInMbps -ge 1) {
        return "$([math]::Round($speedInMbps, 1)) MB/s"
    } elseif ($speedInKbps -ge 1) {
        return "$([math]::Round($speedInKbps, 1)) KB/s"
    } else {
        return "$([math]::Round($bytesPerSec, 1)) B/s"
    }
}

# Fetch the active network adapter dynamically
$activeAdapter = (Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | Select-Object -First 1).InterfaceDescription

# Counter paths for bytes sent/received
$counterBytesSent = "\Network Interface($activeAdapter)\Bytes Sent/sec"
$counterBytesReceived = "\Network Interface($activeAdapter)\Bytes Received/sec"

# ANSI escape codes for green and red
$green = "`e[32m"
$red = "`e[31m"
$reset = "`e[0m"

# Loop indefinitely
while ($true) {
    # Get network statistics
    $bytesSentPerSec = (Get-Counter -Counter $counterBytesSent -SampleInterval 1 -MaxSamples 1).CounterSamples.CookedValue
    $bytesReceivedPerSec = (Get-Counter -Counter $counterBytesReceived -SampleInterval 1 -MaxSamples 1).CounterSamples.CookedValue

    # Calculate speeds using the highest fitting unit
    $uploadSpeed = Calculate-HighestUnit $bytesSentPerSec
    $downloadSpeed = Calculate-HighestUnit $bytesReceivedPerSec

    # Clear current line and write updated info with colored arrows and metrics
    Clear-CurrentLine
    Write-Host "${red}↓${reset} Download: ${red}$downloadSpeed${reset}, ${green}↑${reset} Upload: ${green}$uploadSpeed${reset}" -NoNewline

    # Wait before the next iteration
    Start-Sleep -Seconds 1
}