<#
.SYNOPSIS
BranchCleanup.ps1 is a modular script to clean up local git branches that are no longer existing in the remote repository. The script is divided into several functions to fetch remote data, retrieve local and remote branches, get worktree branches, delete branches, and force delete branches if necessary.

.DESCRIPTION
The script performs the following actions:
- Fetches the latest data from the remote repository if the -NoFetch switch is not specified.
- Lists all local branches and remote branches.
- Identifies worktree branches and filters local branches accordingly.
- Compares local branches against remote branches to identify which branches to delete.
- Deletes branches after user confirmation, and force deletes branches if they are not fully merged.
- Returns to the original location at the end of the script.

.PARAMETERS
-NoFetch: A switch parameter to control whether the script fetches the latest data from the remote repository. If the switch is specified, the script won't fetch from the remote repository.

.EXAMPLE
PS C:\> .\BranchCleanup.ps1 -NoFetch
In this example, the script will skip fetching from the remote repository.

.NOTES
- The script assumes that your current location is the root of your Git repository.
- The functions within the script are modular and can be adjusted or expanded as needed.
- The Delete-Branches function includes a reference parameter to update the branches_to_force_delete array if any branches are not fully merged.
- Make sure to run the script from a Git-enabled command prompt.
#>

# Main script starts here
param(
    [switch]$NoFetch
)

function Fetch-RemoteData {
    param (
        [switch]$NoFetch
    )

    if (-not $NoFetch) {
        git fetch -p
    }
}

function Get-LocalBranches {
    git branch | %{ $_.trim().replace("* ", "").replace("+ ", "") }
}

function Get-RemoteBranches {
    git branch -r | %{ $_.trim() -replace "origin/", "" }
}

function Get-WorktreeBranches {
    $worktree_paths = git worktree list | %{ $_.split(" ")[0] }
    $worktree_branches = @()

    foreach ($path in $worktree_paths) {
        Set-Location -Path $path
        $branch = git rev-parse --abbrev-ref HEAD
        $worktree_branches += $branch
    }

    return $worktree_branches
}

function Delete-Branches {
    param (
        [Array]$branches_to_delete,
        [ref]$branches_to_force_delete
    )

    echo "The following branches will be deleted:"
    $branches_to_delete | %{ echo $_ }
    # Ask for user confirmation
    Write-Host "Do you want to proceed with deletion? [Y/n]" -NoNewline -ForegroundColor Cyan
    $user_input = [System.Console]::ReadKey($true).Key
    Write-Host ""

    if ($user_input -eq 'Y') {
        foreach ($branch in $branches_to_delete) {
            $process = Start-Process -FilePath "git" -ArgumentList "branch -d $branch" -NoNewWindow -Wait -PassThru
            $exitCode = $process.ExitCode

            if ($exitCode -ne 0) {
                Write-Host "Branch $branch is not fully merged.`n" -ForegroundColor Red
                $branches_to_force_delete.Value += $branch
            } else {
                Write-Host "Branch $branch deleted.`n"
            }
        }
    } else {
        Write-Host "Branch deletion aborted by user." -ForegroundColor Yellow
        return
    }
}

function ForceDelete-Branches {
    param (
        [Array]$branches_to_force_delete
    )

    echo "The following branches could not be deleted safely and may require a hard delete:"
    $branches_to_force_delete | %{ echo $_ }
    Write-Host "Do you want to proceed with hard deletion? This can cause loss of commits. [Y/n]" -NoNewline -ForegroundColor Cyan
    $user_input = [System.Console]::ReadKey($true).Key
	Write-Host ""

    if ($user_input -eq 'Y') {
        foreach ($branch in $branches_to_force_delete) {
            git branch -D $branch
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Branch $branch forcefully deleted." -ForegroundColor Yellow
            } else {
                Write-Host "Failed to forcefully delete branch $branch." -ForegroundColor Red
            }
        }
    } else {
        Write-Host "Forceful branch deletion aborted by user." -ForegroundColor Yellow
    }
}

$gitDir = git rev-parse --git-dir 2>$null

if ($null -eq $gitDir) {
    Write-Host "Error: The current directory does not appear to be a Git repository. Please run the script inside a Git repository." -ForegroundColor Red
    exit
}
$original_location = Get-Location

# Fetching remote data if required
Fetch-RemoteData -NoFetch:$NoFetch

# Getting local and remote branches
$local_branches = Get-LocalBranches
$remote_branches = Get-RemoteBranches

# Reverting back to the original location to continue the process
Set-Location -Path $original_location

# Getting worktree branches
$worktree_branches = Get-WorktreeBranches

# Filtering local branches that are not in worktree branches
$local_branches = $local_branches | Where-Object { $_ -notin $worktree_branches }

# Initializing arrays for branches to delete and force delete
$branches_to_delete = @()
$branches_to_force_delete = @()

foreach ($branch in $local_branches) {
    if ($branch -notin $remote_branches) {
        $branches_to_delete += $branch
    }
}

if ($branches_to_delete.Length -gt 0) {
    Delete-Branches -branches_to_delete $branches_to_delete -branches_to_force_delete ([ref]$branches_to_force_delete)
}

if ($branches_to_force_delete.Length -gt 0) {
    ForceDelete-Branches -branches_to_force_delete $branches_to_force_delete
}

if ($branches_to_delete.Length -eq 0 -and $branches_to_force_delete.Length -eq 0) {
    Write-Host "No branches to delete." -ForegroundColor Yellow
}

Set-Location -Path $original_location
