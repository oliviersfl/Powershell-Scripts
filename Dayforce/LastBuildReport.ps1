param (
	$version
)

$dcv = ver.ps1 $version

# Define the path to your 'bin' directory
$binPath = Join-Path -Path $dcv.BaseDir -ChildPath "bin"

# Fetch all DLL and EXE files in the bin directory, not including subdirectories
$files = Get-ChildItem -Path $binPath -File | Where-Object { $_.Extension -eq '.dll' -or $_.Extension -eq '.exe' }

# If no files are found, the script exits
if ($files.Count -eq 0) {
    Write-Host "No build files found in the specified path."
}

# Sort the files by LastWriteTime in descending order and select the first one
$latestFile = $files | Sort-Object LastWriteTime -Descending | Select-Object -First 1

# Display the name and the last write time of the most recently built file
Write-Host "*** Build Report for $version ***"
Write-Host "The latest build was from the file: $($latestFile.Name)"
Write-Host "Build Time: $($latestFile.LastWriteTime)"
Write-Host