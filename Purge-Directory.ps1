param (
    [Parameter(Mandatory=$true)]
    [string]$path
)

# Check if the path exists
if (Test-Path -Path $path) {
    # Deleting the directory recursively
    Remove-Item -Path $path -Recurse -Force
    Write-Host "Directory and its contents have been deleted successfully."
} else {
    Write-Host "The specified path does not exist."
}
