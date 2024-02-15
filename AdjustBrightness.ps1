<#
.SYNOPSIS
This script continuously adjusts the brightness of the monitor.

.DESCRIPTION
AdjustMonitorBrightness.ps1 is a PowerShell script that periodically sets the brightness of the monitor to a specified level. 
It uses WMI (Windows Management Instrumentation) to interact with monitor settings. 
The script runs in an infinite loop, updating the brightness every 5 seconds. 
Brightness level can be specified as a parameter; if not provided, defaults to 5.

.PARAMETER Brightness
The desired brightness level. Default is 5.

.EXAMPLE
.\AdjustMonitorBrightness.ps1
Runs the script with default brightness level (5).

.EXAMPLE
.\AdjustMonitorBrightness.ps1 -Brightness 10
Runs the script with brightness level set to 10.

.NOTES
This script requires administrative privileges to modify system settings.
#>

param(
    [int]$Brightness = 5
)

while ($true) {
    Invoke-CimMethod -InputObject (Get-CimInstance -Namespace root/WMI -ClassName WmiMonitorBrightnessMethods) -MethodName WmiSetBrightness -Arguments @{Brightness=$Brightness; Timeout=1} | Out-Null
    Start-Sleep -Seconds 2
}
