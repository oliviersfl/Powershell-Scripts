param (
    $environment,
    [switch]$revert  # New parameter for revert functionality
)

# Dot source the custom script to load the function and set environment variables
# . setenv.ps1 $environment
$dcv = ver.ps1 $environment

# Assuming $dcv is the variable that has all the required environment properties after sourcing setenv.ps1
$baseDir = $dcv.BaseDir

# Define the relative paths to the .csproj files
$relativePaths = @(
    "Services\Platform\DeviceServices\DeviceServices.csproj",
    "Services\Platform\WBDataSvc\DataSvc\DataSvc.csproj",
    "Services\Platform\WBDataSvc\TestServices\TestServices.csproj",
    "Services\Platform\AdminService\AdminService.csproj",
    "Services\Platform\WBDataSvc\MobileWebService\MobileWebService.csproj"
)
$relativePaths2 = @(
    "Services\Platform\ReportingSvc\ReportingSvc.csproj",
	
    "Services\Platform\DeviceServices\DeviceServices.csproj",
    "Services\Platform\WBDataSvc\DataSvc\DataSvc.csproj",
    "Services\Platform\WBDataSvc\TestServices\TestServices.csproj",
    "Services\Platform\AdminService\AdminService.csproj",
    "Services\Platform\WBDataSvc\MobileWebService\MobileWebService.csproj"
    
	"UI\Help\Help.csproj",
    "UI\OutlookServices\OutlookServices.csproj",
    "UI\SupportLogin\SupportLogin.csproj",
    "UI\SSO\SSO.csproj",
    "UI\SSOLauncher\SSOLauncher.csproj",
    "UI\CandidatePortal\CandidatePortal.csproj"
)

if ($revert) {
    # Navigate to the base directory which should be the root of the git repository
    Push-Location -Path $baseDir

    # Single Git command to revert changes in both .csproj files
    $gitCommand = "git checkout HEAD -- "
    foreach ($relativePath in $relativePaths) {
        # Just use the relative paths for the git command
        $gitCommand += "`"$relativePath`" "
    }
	foreach ($relativePath in $relativePaths2) {
        # Just use the relative paths for the git command
        $gitCommand += "`"$relativePath`" "
    }

    # Execute the git command
    Invoke-Expression $gitCommand

    # Return to the previous directory
    Pop-Location
} else {
	# Part 1: Update WarningAsError to False
    # Loop through each relative path and set TreatWarningsAsErrors to true
    foreach ($relativePath in $relativePaths) {
        $fullPath = Join-Path -Path $baseDir -ChildPath $relativePath
        if (Test-Path $fullPath) {
            # Read the content of the .csproj file
            $content = Get-Content -Path $fullPath -Raw
            
            # Replace <TreatWarningsAsErrors>false</TreatWarningsAsErrors> with true
            $content = $content -replace '(<TreatWarningsAsErrors>)true(</TreatWarningsAsErrors>)', '${1}false$2'

            # Write the modified content back to the file
            Set-Content -Path $fullPath -Value $content
        } else {
            Write-Warning "Could not find file at path: $fullPath"
        }
    }
	
	# Part 2: For csproj that have no WarningAsError property

	# Define the namespace used in csproj files
	$namespace = "http://schemas.microsoft.com/developer/msbuild/2003"

	# Loop through each relative path
	foreach ($relativePath in $relativePaths2) {
		# Construct the full path to the csproj file
		$fullPath = Join-Path $baseDir $relativePath

		# Check if the file exists
		if (Test-Path $fullPath) {
			# Load the csproj file as XML
			$xml = New-Object System.Xml.XmlDocument
			$xml.PreserveWhitespace = $true
			$xml.Load($fullPath)

			# Create a namespace manager
			$nsManager = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
			$nsManager.AddNamespace("msb", $namespace)

			# Find the first PropertyGroup element using the namespace manager
			$propertyGroup = $xml.SelectSingleNode("//msb:Project/msb:PropertyGroup[1]", $nsManager)

			if ($propertyGroup -ne $null) {
				# Create the TreatWarningsAsErrors element
				$treatWarnings = $xml.CreateElement("TreatWarningsAsErrors", $namespace)
				$treatWarnings.InnerText = "false"

				# Add the element to the PropertyGroup
				$propertyGroup.AppendChild($treatWarnings)

				# Save the changes back to the file
				$xml.Save($fullPath)
				Write-Host "Updated: $fullPath"
			} else {
				Write-Host "No PropertyGroup found in: $fullPath"
			}
		} else {
			Write-Host "File not found: $fullPath"
		}
	}
}