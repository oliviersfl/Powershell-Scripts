param (
    [Parameter(Mandatory=$true)]
    [string]$path
)

# Capture the start time
$start_time = Get-Date

# Check if the path exists
if (Test-Path -Path $path) {
    # Deleting the directory recursively
    Remove-Item -Path $path -Recurse -Force
    Write-Host "Directory and its contents have been deleted successfully."
} else {
    Write-Host "The specified path does not exist."
}

# Capture the end time
$end_time = Get-Date

# Calculate the duration
$duration = $end_time - $start_time

# Format the duration to hh:mm:ss
$formatted_duration = "{0:D2}:{1:D2}:{2:D2}" -f $duration.Hours, $duration.Minutes, $duration.Seconds

# Display the duration
Write-Host "Script execution time: $formatted_duration"