<#
.SYNOPSIS
Generates a tree-like view of the file and folder structure starting from the given directory.

.DESCRIPTION
This script uses recursion to traverse through directories and subdirectories, building a string representation of the file and folder structure. It provides options to specify output file, directories or files to exclude, and specific file types to include.

.PARAMETER dir
The root directory from which the tree generation begins.

.PARAMETER outputFile
Optional parameter. If specified, the tree structure will be output to this file. If not specified, the tree structure will be printed on the console.

.PARAMETER exclude
Optional parameter. An array of names to exclude while generating the tree. The script will skip any file or folder that matches any name in this array.

.PARAMETER only
Optional parameter. An array of file types/extensions to include while generating the tree. The script will only print files that match the given types. Each type should be given with a wildcard and the extension (e.g. "*.txt", "*.md"). To specify only the names without extension, just use the name part with a wildcard (e.g. "file*").

.EXAMPLE
GetTree.ps1 -dir "C:\MyFiles" -outputFile "C:\Output\fileTree.txt" -exclude "Temp","Logs" -only "*.txt","*.md"
Generates a tree of the C:\MyFiles directory, excluding any file or folder named "Temp" or "Logs", including only .txt and .md files, and outputs the result to C:\Output\fileTree.txt.

.EXAMPLE
GetTree.ps1 -dir "C:\MyFiles" -only "*.txt","*.md"
Generates a tree of the C:\MyFiles directory on the console, including only .txt and .md files.
#>
param (
    [Parameter(Mandatory=$true)]
    [string]$dir,
    [Parameter(Mandatory=$false)]
    [string]$outputFile,
    [Parameter(Mandatory=$false)]
    [string[]]$exclude,
    [Parameter(Mandatory=$false)]
    [string[]]$only
)

# Checking if the provided directory path is valid
if (!(Test-Path -Path $dir -PathType Container)) {
    Write-Host "Error: The provided directory path is invalid. Please provide a valid path."
    exit
}

$folders = 0
$files = 0
$output = New-Object System.Text.StringBuilder

function Get-Tree {
    param (
        [Parameter(Mandatory=$true)]
        [string]$dir,
        [string]$indent = "",
        [bool]$lastItem = $false,
        [string[]]$exclude,
        [string[]]$only
    )

    $items = Get-ChildItem -Path $dir -Exclude $exclude

    for ($i = 0; $i -lt $items.Count; $i++) {
        $lastItem = $i -eq $items.Count - 1

        if ($lastItem) {
            $prefix = "{0}|- " -f $indent
            $nextIndent = "{0}   " -f $indent
        } else {
            $prefix = "{0}|- " -f $indent
            $nextIndent = "{0}|  " -f $indent
        }

        if ($items[$i].PSIsContainer) {
            if ($null -eq $only -or (Get-ChildItem -Path $items[$i].FullName -Include $only -Recurse)) {
                $null = $script:output.AppendLine("$prefix$($items[$i].Name)")
                $script:folders = $script:folders + 1
                Get-Tree -dir $items[$i].FullName -indent $nextIndent -lastItem $lastItem -exclude $exclude -only $only
            }
        } else {
            if ($null -eq $only -or ($only | Where-Object { $items[$i].Name -like $_ })) {
                $null = $script:output.AppendLine("$prefix$($items[$i].Name)")
                $script:files = $script:files + 1
            }
        }
    }
}

Get-Tree -dir $dir -exclude $exclude -only $only

if (!$outputFile) {
    Write-Host $output.ToString()
} else {
    Out-File -InputObject $output.ToString() -FilePath $outputFile
}

Write-Host ""
Write-Host "Scanned $files files and $folders directories."

Write-Host ""
Write-Host "Scanned $files files and $folders directories."
