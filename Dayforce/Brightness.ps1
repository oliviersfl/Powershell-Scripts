param (
    [Parameter(Mandatory=$true)]
    [ValidateRange(0,100)]
    [int]$BrightnessLevel
)

$BrightnessInstance = Get-CimInstance -Namespace root/WMI -ClassName WmiMonitorBrightnessMethods

if ($null -eq $BrightnessInstance) {
    Write-Error "Unable to find the WmiMonitorBrightnessMethods instance. Your device might not support this method."
    exit 1
}

try {
    $BrightnessInstance | Invoke-CimMethod -methodName WmiSetBrightness -Arguments @{Brightness=$BrightnessLevel; Timeout=0}
    Write-Output "Brightness set to $BrightnessLevel%."
} catch {
    Write-Error "Failed to set brightness: $_"
    exit 1
}
