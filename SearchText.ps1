<#
.SYNOPSIS
    Searches for a specific text in files located in a given directory. Can filter by file type and perform a case sensitive search. 
    Provides the option to include line numbers in output and search subdirectories recursively. 
    Also has the option to display the file paths in a tree structure.

.PARAMETER DirectoryPath
    The path to the directory in which to perform the search.

.PARAMETER SearchText
    The text string to search for in the files.

.PARAMETER FileType
    (Optional) The extension of the file type to search in (without the leading dot). 
    If not provided, all file types are searched.

.PARAMETER CaseSensitive
    (Optional) A switch parameter. If provided, the search is case sensitive.

.PARAMETER Recursive
    (Optional) A switch parameter. If provided, the search is performed recursively in all subdirectories.

.PARAMETER IncludeLineNumbers
    (Optional) A switch parameter. If provided, the output includes line numbers where the search text is found.

.PARAMETER Tree
    (Optional) A switch parameter. If provided, the output file paths are displayed in a tree structure.

.EXAMPLE
    .\Search-Text.ps1 -DirectoryPath "C:\Scripts" -SearchText "function" -FileType "ps1" -CaseSensitive -Recursive -IncludeLineNumbers -Tree
#>

param (
    [Parameter(Mandatory=$true)]
    [string]$DirectoryPath,

    [Parameter(Mandatory=$true)]
    [string]$SearchText,

    [Parameter(Mandatory=$false)]
    [string]$FileType,

    [Parameter(Mandatory=$false)]
    [switch]$CaseSensitive,

    [Parameter(Mandatory=$false)]
    [switch]$Recursive,

    [Parameter(Mandatory=$false)]
    [switch]$IncludeLineNumbers,
	
	[Parameter(Mandatory=$false)]
    [switch]$Tree
)

function Get-RelativePath {
    param (
        [Parameter(Mandatory=$true)]
        [string]$FullPath,

        [Parameter(Mandatory=$true)]
        [string]$RootPath
    )

    return $FullPath.Substring($RootPath.Length).TrimStart('\')
}

function Get-Files {
    param (
        [Parameter(Mandatory=$true)]
        [string]$DirectoryPath,

        [Parameter(Mandatory=$false)]
        [string]$FileType,

        [Parameter(Mandatory=$false)]
        [switch]$Recursive
    )

    if ($FileType) {
        if ($Recursive) {
            return Get-ChildItem -Path $DirectoryPath -Filter "*.$FileType" -Recurse -File
        } else {
            return Get-ChildItem -Path $DirectoryPath -Filter "*.$FileType" -File
        }
    } else {
        if ($Recursive) {
            return Get-ChildItem -Path $DirectoryPath -Recurse -File
        } else {
            return Get-ChildItem -Path $DirectoryPath -File
        }
    }
}

function Get-TreePath {
    param (
        [Parameter(Mandatory=$true)]
        [string]$FilePath,
        
        [Parameter(Mandatory=$true)]
        [string]$RootPath
    )
    
    $relativePathParts = (Get-RelativePath -FullPath $FilePath -RootPath $RootPath).Split('\')
    
    $treePath = ""
    for ($i = 0; $i -lt $relativePathParts.Length; $i++) {
        $treePath += "|" + "  " * $i + "-- " + $relativePathParts[$i] + "`n"
    }
    
    return $treePath.TrimEnd("`n")
}

function Search-TextInFile {
    param (
        [Parameter(Mandatory=$true)]
        [string]$FilePath,

        [Parameter(Mandatory=$true)]
        [string]$SearchText,

        [Parameter(Mandatory=$false)]
        [switch]$CaseSensitive,

        [Parameter(Mandatory=$false)]
        [switch]$IncludeLineNumbers,

        [Parameter(Mandatory=$true)]
        [string]$RootPath,

        [Parameter(Mandatory=$false)]
        [switch]$Tree
    )

    # Get the relative path or tree path of the file based on the $Tree switch
    if ($Tree) {
        $path = Get-TreePath -FilePath $FilePath -RootPath $RootPath
    } else {
        $path = Get-RelativePath -FullPath $FilePath -RootPath $RootPath
    }

    if ($CaseSensitive) {
        $matchInfo = Select-String -Path $FilePath -Pattern $SearchText -CaseSensitive
    } else {
        $matchInfo = Select-String -Path $FilePath -Pattern $SearchText
    }

    if ($matchInfo) {
		if ($IncludeLineNumbers) {
			Write-Host $path -NoNewline
			Write-Host "`nLine $($matchInfo[0].LineNumber): " -NoNewline -ForegroundColor Yellow
			Write-Host $matchInfo[0].Line
		} else {
			Write-Host "$path"
			Write-Host "$($matchInfo[0].Line)" -ForegroundColor Yellow
		}
	}
}

function Search-Text {
    param (
        [Parameter(Mandatory=$true)]
        [string]$DirectoryPath,

        [Parameter(Mandatory=$true)]
        [string]$SearchText,

        [Parameter(Mandatory=$false)]
        [string]$FileType,

        [Parameter(Mandatory=$false)]
        [switch]$CaseSensitive,

        [Parameter(Mandatory=$false)]
        [switch]$Recursive,

        [Parameter(Mandatory=$false)]
        [switch]$IncludeLineNumbers,

        [Parameter(Mandatory=$false)]
        [switch]$Tree
    )

    $files = Get-Files -DirectoryPath $DirectoryPath -FileType $FileType -Recursive:$Recursive

    foreach ($file in $files) {
        Search-TextInFile -FilePath $file.FullName -SearchText $SearchText -CaseSensitive:$CaseSensitive -IncludeLineNumbers:$IncludeLineNumbers -RootPath $DirectoryPath -Tree:$Tree
    }
}

# Call the main function at the end of the script, passing the parameters to it
Search-Text -DirectoryPath (Resolve-Path $DirectoryPath).Path -SearchText $SearchText -FileType $FileType -CaseSensitive:$CaseSensitive -Recursive:$Recursive -IncludeLineNumbers:$IncludeLineNumbers -Tree:$Tree
