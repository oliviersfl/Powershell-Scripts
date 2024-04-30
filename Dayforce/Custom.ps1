# Function to record the start time
function RecordStart {
    $global:startTime = Get-Date
    Write-Host "Start time recorded: $($global:startTime)"
}

# Function to record the end time and calculate the time taken
function RecordEnd {
    $endTime = Get-Date
    Write-Host "End time recorded: $($endTime)"

    # Calculate time difference
    $timeTaken = $endTime - $global:startTime

    # Format and print the time taken
    $timeString = "{0:D2}:{1:D2}:{2:D2}" -f $timeTaken.Hours, $timeTaken.Minutes, $timeTaken.Seconds
    Write-Host "Time taken: $timeString"
}

# Function to customize the PowerShell prompt
function prompt {
    $now = Get-Date -Format "HH:mm"
    $location = Get-Location
    $gitBranch = ''
    try {
        if ((Get-Command git -errorAction SilentlyContinue) -and (& git rev-parse --is-inside-work-tree 2>$null)) {
            $gitBranch = & git rev-parse --abbrev-ref HEAD 2>$null
            if ($gitBranch) {
                $gitBranch = ' [' + $gitBranch + ']'
            }
        }
    } catch {
        $gitBranch = ''
    }
    "$now - $location$gitBranch > "
}

# Function to make a beep sound
function Beep {
    [console]::beep(500, 1200)
}

# Function to determine if an operation can be executed based on the specified interval
function CanExecuteBasedOnInterval($lastUpdated, $interval) {
    $currentTime = Get-Date
    $lastExecutedTime = [datetime]$lastUpdated

    $timeDifference = $currentTime - $lastExecutedTime
    
    switch ($interval[-1]) {
        'h' { return $timeDifference.TotalHours -ge [int]$interval.TrimEnd('h') }
        'd' { return $timeDifference.TotalDays -ge [int]$interval.TrimEnd('d') }
        'w' { return $timeDifference.TotalDays -ge (7 * [int]$interval.TrimEnd('w')) }
    }
    return $false
}

# Global variable to hold the start time
$global:startTime = $null

# Path to the configuration file
$configPath = "C:\Users\P129691\Documents\PowerShell\config.json"

# Read the configuration file and convert from JSON
$config = Get-Content -Path $configPath | ConvertFrom-Json

# Check if commands should be executed based on configuration
if ($config.executeCommands) {
    if (CanExecuteBasedOnInterval $config.lastUpdated $config.interval) {
        # Execute the commands
        Use-Defaults Dayforce.PS.Core
        Use-Defaults Dayforce.PS.Dev

        # Update the last executed time in the configuration file
        $config.lastUpdated = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
        $config | ConvertTo-Json | Set-Content -Path $configPath
    }
}

function getWorkspaces() {
    $currentUserName = $env:USERNAME

    # Define the path to the PowerShell script using the current user name
    $scriptPath = "C:\Dayforce\Utils\${currentUserName}DevCtx.ps1"

    # Source the script to load its variables and hashtables into the current session
    . $scriptPath

    # Assuming $dc is the hashtable of interest, initialize an array to store results
    $workspaces = @()

    # Iterate over each entry in $dc
    foreach ($key in $dc.Keys) {
        # Check if the value associated with the key is a hashtable and contains the 'BaseDir' key
        if ($dc[$key] -is [Hashtable] -and $dc[$key].ContainsKey('BaseDir')) {
            # If conditions are met, add the key to the results array
            $workspaces += $key
        }
    }

    # Output the results
    $workspaces
}