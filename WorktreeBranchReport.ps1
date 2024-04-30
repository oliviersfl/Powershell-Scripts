git worktree list | ForEach-Object {
    $parts = $_ -split '\s+'
    $worktreePath = $parts[0]
    $branchName = git -C "$worktreePath" rev-parse --abbrev-ref HEAD
    "$worktreePath`nBranch: $branchName`n"
}
