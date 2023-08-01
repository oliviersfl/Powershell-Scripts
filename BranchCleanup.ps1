<#
.SYNOPSIS
BranchCleanup.ps1 is a script to clean up local git branches that are no longer existing in the remote repository.

.DESCRIPTION
The script lists all local branches, checks each one if it exists in the remote repository, and deletes it if not. 
Before each deletion, the script asks for user confirmation. 
If the branch is not fully merged and cannot be safely deleted, the script asks for user confirmation before force deletion.

.PARAMETERS
-NoFetch: A switch parameter to control whether the script fetches the latest data from the remote repository. 
If the switch is specified, the script won't fetch from the remote repository.

.EXAMPLE
PS C:\> .\BranchCleanup.ps1 -NoFetch
In this example, the script will skip fetching from the remote repository.

.NOTES
The script assumes that your current location is the root of your Git repository. If not, you may need to navigate there first or adapt the script.
#>

param(
    [switch]$NoFetch
)

# Save the original location
$original_location = Get-Location

if (-not $NoFetch) {
    git fetch -p
}

$local_branches = git branch | %{ $_.trim().replace("* ", "").replace("+ ", "") }
$remote_branches = git branch -r | %{ $_.trim() -replace "origin/", "" } 

# Get paths of all worktrees
$worktree_paths = git worktree list | %{ $_.split(" ")[0] } 

# Initialize worktree_branches array
$worktree_branches = @()

# For each worktree path, get the checked-out branch
foreach ($path in $worktree_paths) {
    Set-Location -Path $path
    $branch = git rev-parse --abbrev-ref HEAD
    $worktree_branches += $branch
}

# Get back to the original location (not the script's location)
Set-Location -Path $original_location

# Filter out checked-out branches
$local_branches = $local_branches | Where-Object { $_ -notin $worktree_branches }

# Initialize deletion and hard deletion arrays
$branches_to_delete = @()
$branches_to_force_delete = @()

foreach ($branch in $local_branches) {
    if ($branch -notin $remote_branches) {
        $branches_to_delete += $branch
    }
}

# Print out the branches to be deleted
if ($branches_to_delete.Length -gt 0) {
    echo "The following branches will be deleted:"
    $branches_to_delete | %{ echo $_ }

    # Ask for user confirmation
    Write-Host "Do you want to proceed with deletion? [Y/n]" -NoNewline -ForegroundColor Cyan
    $user_input = [System.Console]::ReadKey($true).Key
	Write-Host ""

    if ($user_input -eq 'Y') {
        echo "" # Just to add a newline after the prompt

        foreach ($branch in $branches_to_delete) {
            # Run the git command as a separate process
			$process = Start-Process -FilePath "git" -ArgumentList "branch -d $branch" -NoNewWindow -Wait -PassThru
			$exitCode = $process.ExitCode

			if ($exitCode -ne 0) {
				Write-Host "Branch $branch is not fully merged.`n" -ForegroundColor Red
				$branches_to_force_delete += $branch
			} else {
				Write-Host "Branch $branch deleted.`n"
			}
        }
		
		Write-Host ""
    } else {
        echo "" # Just to add a newline after the prompt
        Write-Host "Branch deletion aborted by user." -ForegroundColor Yellow
        return
    }
}

# If there are branches to be force deleted, prompt user for confirmation
if ($branches_to_force_delete.Length -gt 0) {
    echo "The following branches could not be deleted safely and may require a hard delete:"
    $branches_to_force_delete | %{ echo $_ }

    Write-Host "Do you want to proceed with hard deletion? This can cause loss of commits. [Y/n]" -NoNewline -ForegroundColor Cyan
    $user_input = [System.Console]::ReadKey($true).Key

    if ($user_input -eq 'Y') {
        echo "" # Just to add a newline after the prompt

        # Force delete branches
        foreach ($branch in $branches_to_force_delete) {
            git branch -D $branch
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Branch $branch forcefully deleted." -ForegroundColor Yellow
            } else {
                Write-Host "Failed to forcefully delete branch $branch." -ForegroundColor Red
            }
        }
    } else {
        Write-Host "" # Just to add a newline after the prompt
        Write-Host "Forceful branch deletion aborted by user." -ForegroundColor Yellow
    }
}

if ($branches_to_delete.Length -eq 0 -and $branches_to_force_delete.Length -eq 0) {
    Write-Host "No branches to delete." -ForegroundColor Yellow
}

# Return to the original location at the end of the script
Set-Location -Path $original_location
