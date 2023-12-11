<#
.SYNOPSIS
This PowerShell script monitors and displays mouse activity, calculating active and idle periods based on mouse movements.

.DESCRIPTION
This script continuously tracks the last mouse input time and calculates the duration of active and idle periods. It's designed for Windows systems and uses native Win32 API functions.

.PARAMETERS
idleTime (Optional)
- Type: Integer
- Default: 2 minutes
- Description: Threshold in minutes for determining idle time. If the mouse is inactive longer than this, the user is considered idle.

.FUNCTIONALITY
- Monitors mouse activity using P/Invoke and .NET interop.
- Updates active and total active durations based on mouse activity.
- Outputs real-time information about active and idle durations.

.USAGE
- Run in a PowerShell window.
- Displays real-time mouse activity information.
- To stop, use Ctrl+C.

.APPLICATION
Useful for tracking user activity, automated testing, or triggering events after periods of inactivity.

#>

param (
    $idleTime = 2  # idle time in minutes; default is set to 2
)

# Define a P/Invoke to call a native function for getting last mouse input time
Add-Type -AssemblyName System.Windows.Forms
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class UserInput {
    [DllImport("user32.dll", SetLastError=true)]
    private static extern bool GetLastInputInfo(ref LASTINPUTINFO plii);

    [StructLayout(LayoutKind.Sequential)]
    private struct LASTINPUTINFO {
        public uint cbSize;
        public uint dwTime;
    }

    public static DateTime GetLastMouseInputTime() {
        LASTINPUTINFO info = new LASTINPUTINFO();
        info.cbSize = (uint)Marshal.SizeOf(info);
        if (!GetLastInputInfo(ref info))
            throw new System.ComponentModel.Win32Exception(Marshal.GetLastWin32Error());

        // Convert the last input tick to a DateTime
        DateTime bootTime = DateTime.Now.AddMilliseconds(-Environment.TickCount);
        DateTime lastInputTime = bootTime.AddMilliseconds(info.dwTime);
        return lastInputTime;
    }
}
"@

# Initialize variables
$lastActiveTime = $null
$firstActiveTime = $null
$activeDuration = [TimeSpan]::FromSeconds(0)
$totalActiveDuration = [TimeSpan]::FromSeconds(0)
$isActive = $false
$hasBeenActive = $false

# Loop indefinitely
while ($true) {
    Start-Sleep -Seconds 1

    try {
        $lastMouseInputTime = [UserInput]::GetLastMouseInputTime()
    } catch {
        Write-Error "Error retrieving last mouse input time: $_"
        continue
    }

    $idleDuration = ((Get-Date) - $lastMouseInputTime).TotalSeconds
    $consoleWidth = $Host.UI.RawUI.WindowSize.Width
    $maxOutputLength = $consoleWidth - 1

    if ($idleDuration -lt ($idleTime * 60)) {
        $activeDuration = $activeDuration.Add([TimeSpan]::FromSeconds(1))
        $totalActiveDuration = $totalActiveDuration.Add([TimeSpan]::FromSeconds(1))

        if (-not $isActive) {
            $lastActiveTime = Get-Date
            $isActive = $true

            if (-not $hasBeenActive) {
                $firstActiveTime = Get-Date
                $hasBeenActive = $true
            }
        }

        $output = "Active: $($activeDuration.ToString('hh\:mm\:ss')) Since: $lastActiveTime. Total: $($totalActiveDuration.ToString('hh\:mm\:ss')) Since: $firstActiveTime"
    } else {
        $activeDuration = [TimeSpan]::FromSeconds(0)
        $isActive = $false
        $output = "Idle: >$idleTime mins. Reset counter. Total: $($totalActiveDuration.ToString('hh\:mm\:ss'))"
    }

    $paddedOutput = $output.PadRight($maxOutputLength).Substring(0, $maxOutputLength)
    Write-Host "`r$paddedOutput" -NoNewline
}
