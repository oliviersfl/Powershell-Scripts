# Initialization
$targetIP = "8.8.8.8"
$pingTimes = New-Object System.Collections.Queue
$timeoutCount = 0
$firstIteration = $true

while ($true) {
    $currentTime = (Get-Date).ToString('hh:mm:ss')
    $pingOutput = ping $targetIP -n 1
    $result = $pingOutput | Select-String "Reply from"
    $timeout = $pingOutput | Select-String "Request timed out."

    if ($result) {
        if ($pingTimes.Count -ge 100) {
            $oldestPing = $pingTimes.Dequeue()
            if ($oldestPing -eq "timeout") {
                $timeoutCount--
            }
        }
        # Extract ping time in ms
        $time = [int](($result -split "time=")[1] -split "ms")[0].Trim()
        $pingTimes.Enqueue($time)
    } elseif ($timeout) {
        if ($pingTimes.Count -ge 100) {
            $oldestPing = $pingTimes.Dequeue()
            if ($oldestPing -ne "timeout") {
                $timeoutCount--
            }
        }
        $pingTimes.Enqueue("timeout")
        $timeoutCount++
    }

    # Calculating stats for the last 100 pings
    $validPingTimes = $pingTimes | Where-Object { $_ -ne "timeout" }
    $averagePing = ($validPingTimes | Measure-Object -Average).Average
    $minPing = ($validPingTimes | Measure-Object -Minimum).Minimum
    $maxPing = ($validPingTimes | Measure-Object -Maximum).Maximum

    # For subsequent iterations, move cursor up two lines to overwrite
    if (-not $firstIteration) {
        $pos = $host.UI.RawUI.CursorPosition
        $pos.Y -= 2
        $host.UI.RawUI.CursorPosition = $pos
    } else {
        $firstIteration = $false
    }

    # Write average, min, max, timeout count, then write the result
    Write-Host "[$currentTime] Avg: $($averagePing -as [int])ms | Min: $($minPing)ms | Max: $($maxPing)ms | Timeouts (last 100): $timeoutCount"
    Write-Host "$result$timeout"

    Start-Sleep -Milliseconds 1000 # Optional: Sleep for 1 second
}
