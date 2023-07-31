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
