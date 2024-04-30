# Define the file path
$filePath = "$env:USERPROFILE\Documents\Powershell\config.txt"

# Check if the file exists
if (Test-Path $filePath) {
    # Read the content of the file
    $content = Get-Content $filePath | Out-String | ForEach-Object { $_.Trim() }

    # Check the content and toggle the value
    if ($content -eq 'true') {
        'false' | Out-File $filePath
        Write-Host "Value has been set to 'false'."
    } elseif ($content -eq 'false') {
        'true' | Out-File $filePath
        Write-Host "Value has been set to 'true'."
    } else {
        Write-Host "The content of the file is neither 'true' nor 'false'."
    }
} else {
    Write-Host "File not found at $filePath"
}
