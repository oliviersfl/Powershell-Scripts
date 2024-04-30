<#
.SYNOPSIS
    This script is designed to delete all 'node_modules' directories recursively from a specified base path in a PowerShell environment. It's particularly useful for cleaning up node modules in a development environment to reclaim disk space or prepare for a fresh installation of dependencies.

.DESCRIPTION
    The script begins by setting up the environment with the specified version through the .setenv command. It then defines a base path rooted at the directory specified by $dcv.BaseDir, targeting the 'LegacyFrontEnd\src' subdirectory for cleanup.

    It proceeds to recursively find and delete every 'node_modules' directory under the specified base path. The script handles hidden directories and uses forceful deletion to ensure that all node_modules directories, regardless of their attributes, are completely removed. This operation is performed while suppressing all confirmation prompts to streamline the process.

    The script also measures and reports the total execution time, providing insight into the duration of the cleanup process.

.PARAMETER version
    The version parameter is mandatory and specifies the environment version to be set up by the .setenv command. This allows the script to operate in the context of a specific project or environment configuration.

.EXAMPLE
    .\ClearNodeModules.ps1 -version tip
    This example runs the script for the environment version "tip", deleting all 'node_modules' directories under the specified base path for that version.

.NOTES
    - Ensure you have the necessary permissions to delete the directories within the specified path.
    - The script forcibly removes directories and suppresses confirmation prompts; use with caution to avoid unintended data loss.
    - Execution time is reported at the end for performance tracking.

#>

param (
    [Parameter(Mandatory = $true, Position = 0)]
    $version
)
$dcv = ver.ps1 $version

$basePath = "$($dcv.BaseDir)LegacyFrontEnd\src"
$startTime = Get-Date

# Delete every 'node_modules' directory under $basePath recursively
Get-ChildItem -Path $basePath -Directory -Recurse -Force -Filter 'node_modules' | ForEach-Object {
    Remove-Item -Path $_.FullName -Recurse -Force -Confirm:$false
    Write-Output "Deleted node_modules folder: $($_.FullName)"
}

$endTime = Get-Date
$elapsedTime = $endTime - $startTime
$elapsedTimeString = '{0:hh\:mm\:ss}' -f $elapsedTime
Write-Host "Script completed in $elapsedTimeString."