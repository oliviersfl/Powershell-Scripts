<#
.SYNOPSIS
This PowerShell script automates the synchronization of a local git repository with an upstream repository. It is designed to ensure that the local repository stays updated with the latest changes from the upstream source.

.DESCRIPTION
The script performs the following operations:
1. Sets up the environment based on a specified version.
2. Checks for the presence of an 'upstream' remote in the local repository. If not present, it adds the 'upstream' remote using a predefined URL.
3. Fetches the latest changes from the upstream repository.
4. Checks if the current local branch exists in the upstream repository. If not, the script aborts for not pushing a new branch in the forked repository.
5. Attempts to check out the current local branch quietly.
6. Merges changes from the corresponding upstream branch into the local branch.
7. Pushes the merged changes to the user's fork on GitHub.

.PARAMETER version
Specifies the version of the environment to set for the current execution context.

.EXAMPLE
Sync.ps1 66

This example sets up the environment for version 66, checks for the 'upstream' remote, fetches the latest changes from the upstream repository, ensures the current branch exists upstream, merges changes, and pushes the merged changes to GitHub. Note: default is 'tip' if non specified

.NOTES
Ensure that you have the necessary permissions to push changes to the remote repository on GitHub and that your local git configuration is correctly set up.

#>

param (
	$version,
    [switch]$build
)

$startTime = Get-Date

$originalDir = Get-Location

# . setenv $version
$dcv = ver.ps1 $version

cd $dcv.BaseDir

# Check if 'upstream' remote is already set
$upstreamSet = git remote | Select-String -Pattern "upstream"

if (-Not $upstreamSet) {
    # 'upstream' is not set, so add it using the URL from $dcv.Repo
    git remote add upstream "https://github.com/DayforceGlobal/dayforce"
    Write-Host "Upstream remote added: https://github.com/DayforceGlobal/dayforce"
} else {
    Write-Host "Upstream remote is already set."
}

# SYNCING PROCESS
#############################################
# Fetch the latest changes from the upstream repository
git fetch upstream

# Get Name of Current Branch
$currentBranch = git rev-parse --abbrev-ref HEAD

# Check if the current branch exists in the upstream repository
$branchExists = git ls-remote --heads upstream | Select-String "$currentBranch"

if (-not $branchExists) {
    Write-Host "The branch '$currentBranch' does not exist in the upstream repository. Aborting..." -ForegroundColor Red
    exit 1 # Exit the script with an error status
}

# Attempt to check out the current branch
try {
    git checkout $currentBranch -q # '-q' for quiet mode, less output
} catch {
    Write-Host "Error checking out $currentBranch. It might be checked out elsewhere. Aborting..." -ForegroundColor Red
    exit 1 # Exit the script with an error status
}

try {
    # Merge the changes from the upstream branch into your local branch
    git merge "upstream/$currentBranch"
} catch {
    Write-Host "Error merging upstream/$currentBranch. The branch might not exist upstream. Aborting..." -ForegroundColor Red
    exit 1 # Exit the script with an error status
}

# Push the changes to your fork on GitHub
git push origin $currentBranch
#############################################

if($build) {
    dbupdate.ps1 $version
    r.ps1 $version -nopull
}

cd $originalDir

$endTime = Get-Date
$duration = $endTime - $startTime
$formattedDuration = $duration.ToString("hh\:mm\:ss")
Write-Host "Total Execution Time: $formattedDuration"