<#
.SYNOPSIS
SwitchWorkspace.ps1 - A script for switching IIS website physical paths to different application workspaces.

.DESCRIPTION
This script provides an automated mechanism for developers to switch the active workspace for an application hosted in IIS. It enables the testing of different versions or configurations of the application by dynamically altering the physical paths of IIS websites to point to different directories. The script supports several options, such as specifying the version, toggling environment validation, setting read-only mode, and choosing the protocol (HTTP or HTTPS).

.PARAMETER version
Specifies the version of the workspace to switch to.

.PARAMETER NoEnvValidate
Switch parameter to bypass environment validation checks.

.PARAMETER DF2
Switch parameter to indicate the use of an alternative workspace. Website should be named "MyDayforce2"

.PARAMETER ReadOnly
Switch parameter to set the script to read-only mode, which doesn't alter any configurations but reports the current settings.

.PARAMETER Protocol
Defines the protocol to use (HTTP or HTTPS). Defaults to HTTP if not specified.

.PARAMETER Elevated
Switch parameter to attempt running the script with elevated permissions (as an administrator).

.EXAMPLE
.\SwitchWorkspace.ps1 tip 
Switches the IIS workspace to version tip, targets main Dayforce Website

.EXAMPLE
.\SwitchWorkspace.ps1 66 -DF2
Switches the IIS workspace to version 66, targets the alternative Dayforce Website

.EXAMPLE
.\SwitchWorkspace.ps1 wfmSvc -Protocol "https"
Switches the IIS workspace to version wfmSvc, targets the main Dayforce Website, and sets the protocol to HTTPS.

.EXAMPLE
.\SwitchWorkspace.ps1 -ReadOnly
Reports the current physical paths of the IIS websites without making any changes.

.NOTES
Ensure that the necessary IIS websites and application directories are properly configured before running this script. If using the HTTPS protocol, ensure that the SSL certificate with the corresponding thumbprint is installed in the machine's certificate store.

# Requires running as Administrator for modifying IIS configurations.
# The script will attempt to elevate permissions if not already running as an administrator.

#>
param($version, [Switch]$NoEnvValidate, [Switch]$DF2 = $false,[Switch]$ReadOnly = $false,
        [ValidateSet("http","https")]
		[string]
		$Protocol,
		[switch]$Elevated
)

if(!$Protocol){
	#Probably have a more elegant way to set default
	$Protocol = "http"
}

function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if ((Test-Admin) -eq $false)  {
    if ($elevated) {
		ECHO "tried to elevate, did not work, aborting. Try invoking in Admin mode manually."
    } 
	else {
		ECHO "Attempting to elevate"

		$paramsSet = " -Protocol $($Protocol) ";

		if ($version)
		{
		$paramsSet += " -version $($version)";
		}
		
		if($DF2){
		$paramsSet += " -DF2 "
		}

		if($ReadOnly){
		$paramsSet += " -ReadOnly "
		}

        Start-Process powershell.exe -Verb RunAs -ArgumentList (' -noexit "{0}" "{1}" -elevated' -f $MyInvocation.MyCommand.Name, $paramsSet)
    }
}
else
{
    $dcv = ver.ps1 $version
    Add-Type -Path "C:\Windows\System32\inetsrv\Microsoft.Web.Administration.dll"
    
	if(!$ReadOnly) {
        $serverManager = New-Object Microsoft.Web.Administration.ServerManager

        if(!$DF2) {
            $sitesToModify = @{
                "DataSvc" = "$($dcv.BaseDir)bin\_PublishedWebsites\DataSvc";
                "AdminService" = "$($dcv.BaseDir)bin\_PublishedWebsites\AdminService";
                "TestServices" = "$($dcv.BaseDir)bin\_PublishedWebsites\TestServices";
                "MyDayforce" = "$($dcv.BaseDir)bin\_PublishedWebsites\MyDayForce";
                "ReportingService" = "$($dcv.BaseDir)bin\_PublishedWebsites\ReportingSvc";
                "DeviceService" = "$($dcv.BaseDir)bin\_PublishedWebsites\DeviceService";
                "CandidatePortal" = "$($dcv.BaseDir)bin\_PublishedWebsites\CandidatePortal";
                "MobileService" = "$($dcv.BaseDir)bin\_PublishedWebsites\MobileService";
            }
        } else {
            $sitesToModify = @{
                "MyDayforce2" = "$($dcv.BaseDir)bin\_PublishedWebsites\MyDayForce";
            }
        }

        foreach ($siteName in $sitesToModify.Keys) {
            $site = $serverManager.Sites[$siteName]
            if ($site -ne $null) {
                $app = $site.Applications["/"]
                $vDir = $app.VirtualDirectories["/"]
                $vDir.PhysicalPath = $sitesToModify[$siteName]
                Write-Host "Updating site $siteName physical path to $($sitesToModify[$siteName])"
            } else {
                Write-Warning "Site $siteName not found."
            }
        }

        $serverManager.CommitChanges()

        if(!$DF2) {
            Write-Host "Switching to WorkTree $($dcv.BaseDir)"
        } else {
            Write-Host "Switching to WorkTree (2) $($dcv.BaseDir)"
        }
    }

	else { # Read-Only Part
        Import-Module -Name Microsoft.PowerShell.Management -ErrorAction SilentlyContinue

        $serverManager = New-Object Microsoft.Web.Administration.ServerManager

        $siteName1 = "mydayforce"
        $siteName2 = "mydayforce2"

        $site1 = $serverManager.Sites | Where-Object { $_.Name -eq $siteName1 }
        $site2 = $serverManager.Sites | Where-Object { $_.Name -eq $siteName2 }

        if ($site1) {
            $_df1 = $site1.Applications["/"].VirtualDirectories["/"].PhysicalPath
            Write-Output "MyDayforce - $_df1"
        } else {
            Write-Warning "Could not find the site or physical path for $siteName1"
        }

        if ($site2) {
            $_df2 = $site2.Applications["/"].VirtualDirectories["/"].PhysicalPath
            Write-Output "MyDayforce2 - $_df2"
        } else {
            Write-Warning "Could not find the site or physical path for $siteName2"
        }
    }

    $port = 51000
    $defaultThumbprint = "d1f89aa976d3d6e93664f8ecdbade8fe33485159" #Replace here if assigining Thumbprint value automatically does not work

    # Assuming $port and $protocol are defined earlier in your script
    Add-Type -Path "C:\Windows\System32\inetsrv\Microsoft.Web.Administration.dll"
    $serverManager = New-Object Microsoft.Web.Administration.ServerManager

    # Remove existing bindings on the specified port
    $site = $serverManager.Sites["MyDayforce"]
    if ($site -ne $null) {
        $site.Bindings.Clear()
        $binding = $site.Bindings.Add("*:${port}:", $protocol)
        $serverManager.CommitChanges()
    } else {
        Write-Error "Site 'MyDayforce' not found."
    }

    if ($Protocol -eq "https") {
        ECHO "Setting to SSL"

        # Fetch the certificate from the cert store
        $cert = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object { $_.Thumbprint -eq $defaultThumbprint }

        if ($cert -ne $null) {
            # If found, use its thumbprint
            $thumbprintToUse = $cert.Thumbprint
            Write-Output "Found certificate with thumbprint: $thumbprintToUse"
        } else {
            # If not found, use the hardcoded thumbprint
            $thumbprintToUse = $defaultThumbprint
            Write-Output "Using default certificate with thumbprint: $thumbprintToUse"
        }

        # Remove existing https binding if it exists
        netsh http delete sslcert ipport=0.0.0.0:$port

        # Add the new https binding
        netsh http add sslcert ipport=0.0.0.0:$port certhash=$thumbprintToUse appid='{4dc3e181-e14b-4a21-b022-59fc669b0914}' # Replace with your actual appid

        Write-Output "HTTPS binding updated for port $port."
    }
	
}