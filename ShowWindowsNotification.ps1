<#
.SYNOPSIS
Displays a Windows notification balloon tip with a custom message and title.

.DESCRIPTION
This PowerShell script uses Windows Forms to display a notification balloon tip at the system tray. 
It does this by creating a NotifyIcon object and setting its properties to display the balloon tip 
with the specified message and title.

The script is designed to run asynchronously, meaning it will not block the PowerShell console 
from receiving further commands while the notification is displayed.

.PARAMETERS
-Message
    The message that appears in the notification.
    Default: "This is your message"

-Title
    The title of the notification.
    Default: "Notification Title"

.EXAMPLE
Running the script with default parameters:
    .\ShowWindowsNotification.ps1

.EXAMPLE
Running the script with custom message and title:
    .\ShowWindowsNotification.ps1 -Message "Custom Message" -Title "Custom Title"

.NOTES
The script uses a separate runspace to run the notification logic asynchronously.

The notification will be displayed for the default duration determined by the system settings.

Make sure to adjust the execution policy on your system if you're unable to run PowerShell scripts.
#>

param (
    [string]$Message = "This is your message",
    [string]$Title = "Notification Title",
    [System.Windows.Forms.ToolTipIcon]$IconType = [System.Windows.Forms.ToolTipIcon]::Info
)

# Load necessary assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create and configure a new runspace
$runspace = [runspacefactory]::CreateRunspace()
$runspace.ApartmentState = "STA"
$runspace.ThreadOptions = "ReuseThread"
$runspace.Open()

# Create a new script block for the notification code
$scriptblock = {
    param (
        [string]$Message,
        [string]$Title,
        [System.Windows.Forms.ToolTipIcon]$IconType
    )
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $notifyIcon = New-Object System.Windows.Forms.NotifyIcon

    # Set properties
    $notifyIcon.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName)
    $notifyIcon.BalloonTipIcon = $IconType
    $notifyIcon.BalloonTipText = $Message
    $notifyIcon.BalloonTipTitle = $Title
    $notifyIcon.Visible = $True

    # Show balloon tip
    $notifyIcon.ShowBalloonTip(0)  # Default duration set by system

    # Remove the icon after 10 seconds
    Start-Sleep -Seconds 10
    $notifyIcon.Dispose()
}

# Create a new PowerShell instance and add the script block
$ps = [powershell]::Create().AddScript($scriptblock).AddArgument($Message).AddArgument($Title).AddArgument($IconType)

# Associate the PowerShell instance with the runspace
$ps.Runspace = $runspace

# Begin the invocation and continue
$null = $ps.BeginInvoke()
