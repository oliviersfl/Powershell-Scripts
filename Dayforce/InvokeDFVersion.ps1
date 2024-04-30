<#
.SYNOPSIS
This script invokes a version checking command for specified parameters and extracts keys from the output.

.DESCRIPTION
This PowerShell script is designed to invoke a version checking function (Invoke-DFVersion) with a user-defined parameter and optionally,
a count of iterations. It supports three parameters: 'DFELEMENTPARAM', 'Client', and 'DFELEMENT'.
The script runs the version checking command the number of times specified by the user (default is once) and parses the output to extract keys.
It then consolidates and displays the extracted keys.

.PARAMETER parameter
The parameter to be passed to the Invoke-DFVersion command.
It must be one of three predefined values: 'DFELEMENTPARAM', 'Client', or 'DFELEMENT'.
This parameter is mandatory.

.PARAMETER count
The number of times to invoke the version checking command.
This parameter is optional and defaults to 1 if not specified.

.EXAMPLE
PS> .\ScriptName.ps1 -parameter 'Client' -count 3
This example runs the script with the parameter set to 'Client', executing the version checking command three times and outputs the extracted keys.

.NOTES
Ensure that the Invoke-DFVersion command is available and functional before running this script.
#>

[CmdletBinding()]
param(
    [Parameter(Position=0, Mandatory=$true)]
    [ValidateSet('DFELEMENTPARAM', 'Client', 'DFELEMENT')]
    [string]$parameter,

    [Parameter(Position=1)]
    [int]$count = 1
)

$keyText = ""
for ($i = 1; $i -le $count; $i++) {
    $output = Invoke-DFVersion $parameter
    Write-Output $output
    $matches = [regex]::Matches($output, 'Use this key: (\d+)')
    foreach ($match in $matches) {
        $key = $match.Groups[1].Value
        if ($keyText -ne "") {
            $keyText += ", "
        }
        $keyText += $key
    }
}

Write-Output "Keys found: $keyText"