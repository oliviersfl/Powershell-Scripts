<#
.SYNOPSIS
    This PowerShell script monitors user activity and idle time on a Windows system.

.DESCRIPTION
    The script uses P/Invoke to call native Windows API functions for tracking the last time the user interacted with the system.
    It then calculates the duration of user activity and idle time, displaying this information continuously in the console.

.PARAMETER idleTime
    Specifies the threshold for idle time in minutes. If user idle time exceeds this threshold, the active time counter is reset.
    The default value is 2 minutes.

.EXAMPLE
    .\Active.ps1 -idleTime 5
    Runs the script setting the idle time threshold to 5 minutes.

.NOTES
    The script updates every second and adjusts its output to fit the console window width.
#>

param (
    [int]$idleTime = 2  # idle time in minutes; default is set to 2
)

# Define a P/Invoke to call a native function for getting last input time
Add-Type -AssemblyName System.Windows.Forms
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class UserInput {
    [DllImport("user32.dll", SetLastError=false)]
    private static extern bool GetLastInputInfo(ref LASTINPUTINFO plii);

    [StructLayout(LayoutKind.Sequential)]
    private struct LASTINPUTINFO {
        public uint cbSize;
        public uint dwTime;
    }

    public static uint GetLastInputTime() {
        LASTINPUTINFO info = new LASTINPUTINFO();
        info.cbSize = (uint)Marshal.SizeOf(info);
        GetLastInputInfo(ref info);
        return info.dwTime;
    }
}
"@

# Initialize variables
$lastActiveTime = $null
$firstActiveTime = $null
$activeDuration = [TimeSpan]::FromSeconds(0)
$totalActiveDuration = [TimeSpan]::FromSeconds(0)
$isActive = $false  # New flag variable to track active state

# Loop indefinitely
while ($true) {
    Start-Sleep -Seconds 1

    $lastBootUpTime = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime

    # Get system uptime and last input time
    $systemUptime = [math]::Round(((Get-Date) - $lastBootUpTime).TotalMilliseconds)
    $lastInputTime = [UserInput]::GetLastInputTime()

    # Calculate idle time
    $idleDuration = ($systemUptime - $lastInputTime) / 1000

    $consoleWidth = $Host.UI.RawUI.WindowSize.Width  # Get the console window width
    $maxOutputLength = $consoleWidth - 1  # Adjust the max output length to fit within the console window

    if ($idleDuration -lt ($idleTime * 60)) {
        $activeDuration = $activeDuration.Add([TimeSpan]::FromSeconds(1))
        $totalActiveDuration = $totalActiveDuration.Add([TimeSpan]::FromSeconds(1))
        
        # Set $lastActiveTime and $firstActiveTime only when first becoming active
        if (-not $isActive) {
            $lastActiveTime = Get-Date
            $isActive = $true
            
            if (-not $hasBeenActive) {
                $firstActiveTime = Get-Date  # Set this only the first time the user becomes active
                $hasBeenActive = $true
            }
        }

        # Update this line to include $firstActiveTime
        #$output = "You've been active for $($activeDuration.ToString('hh\:mm\:ss')) since $lastActiveTime. Total active time in this session since ${firstActiveTime}: $($totalActiveDuration.ToString('hh\:mm\:ss'))"
		$output = "Active: $($activeDuration.ToString('hh\:mm\:ss')) Since: $lastActiveTime. Total: $($totalActiveDuration.ToString('hh\:mm\:ss')) Since: $firstActiveTime"
    } else {
        $activeDuration = [TimeSpan]::FromSeconds(0)
        $isActive = $false  # Reset flag when becoming idle
        #$output = "Idle time exceeded $idleTime minutes. Resetting active time counter. Total active time in this session so far: $($totalActiveDuration.ToString('hh\:mm\:ss'))"
		$output = "Idle: >$idleTime mins. Reset counter. Total: $($totalActiveDuration.ToString('hh\:mm\:ss'))"
    }

    # Pad the output string with spaces and then trim it to fit within the console window
    $paddedOutput = $output.PadRight($maxOutputLength).Substring(0, $maxOutputLength)

    Write-Host "`r$paddedOutput" -NoNewline
}