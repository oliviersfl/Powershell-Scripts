<#
.SYNOPSIS
    BranchCleanup.ps1 is a PowerShell script that identifies and deletes local Git branches that do not have a corresponding remote branch and are not currently checked out in any worktree.

.PARAMETERS
    -NoFetch: A switch parameter. If specified, the script will skip the 'git fetch' command. Useful when you've recently fetched remote updates and want to avoid fetching again.
    
.USAGE
    ./BranchCleanup.ps1               # Run the script normally.
    ./BranchCleanup.ps1 -NoFetch      # Run the script without fetching updates from remote.
    
.DESCRIPTION
    The script first checks if the NoFetch parameter is not specified, in which case it fetches updates from the remote repository. It then identifies all local and remote branches.

    The script traverses through each local worktree, identifies the currently checked-out branch, and excludes these branches from the list of local branches.

    It then checks the modified list of local branches against the list of remote branches, identifying which local branches do not have a corresponding remote branch. These branches are added to the deletion list.

    If any branches are found to be on the deletion list, the script prompts the user for confirmation to proceed with deletion. Upon user confirmation, it attempts to delete each branch, displaying a success or failure message for each one.

    If no branches are on the deletion list, the script informs the user that there are no branches to delete.

    Finally, the script returns the working directory to the original location.

.NOTES
    The script handles errors resulting from the 'git branch -d' command, hence, it will not stop execution if a branch cannot be deleted.
    If the script fails to delete a branch, it will print an error message and continue with the next branch.

    It's important to note that the script does not handle other potential Git errors, so if other Git commands fail, they could affect the script's behavior.
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

# Initialize deletion array
$branches_to_delete = @()

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
    Write-Host "Do you want to proceed with deletion? [Y/n]" -NoNewline
    $user_input = [System.Console]::ReadKey($true).Key

    if ($user_input -eq 'Y') {
        echo "" # Just to add a newline after the prompt
        foreach ($branch in $branches_to_delete) {
            git branch -d $branch
            if ($LASTEXITCODE -eq 0) {
                echo "Branch $branch deleted."
                echo ""
            } else {
                echo "Failed to delete branch $branch."
            }
        }
    } else {
        echo "" # Just to add a newline after the prompt
        echo "Branch deletion aborted by user."
    }
} else {
    echo "No branches to delete."
}

# Return to the original location at the end of the script
Set-Location -Path $original_location
