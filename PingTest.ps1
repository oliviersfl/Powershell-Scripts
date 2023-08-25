# Initialization
$targetIP = "8.8.8.8"
$pingTimes = New-Object System.Collections.Queue
$timeoutCount = 0

try {
    while ($true) {
		$currentTime = (Get-Date).ToString('hh:mm:ss')
		$pingOutput = ping $targetIP -n 1
		$result = $pingOutput | Select-String "Reply from"
		$timeout = $pingOutput | Select-String "Request timed out."

        # Dequeue oldest result if queue has reached capacity and adjust the timeout count accordingly
		if ($pingTimes.Count -ge 100) {
			$oldestPing = $pingTimes.Dequeue()
			if ($oldestPing -eq "timeout") {
				$timeoutCount--
			}
		}

		if ($result) {
			# Extract ping time in ms
			$time = [int](($result -split "time=")[1] -split "ms")[0].Trim()
			$pingTimes.Enqueue($time)
		} elseif ($timeout) {
			$pingTimes.Enqueue("timeout")
			$timeoutCount++
		}

		# Calculating stats for the last 100 pings
		$validPingTimes = $pingTimes | Where-Object { $_ -ne "timeout" }
		$averagePing = ($validPingTimes | Measure-Object -Average).Average
		$minPing = ($validPingTimes | Measure-Object -Minimum).Minimum
		$maxPing = ($validPingTimes | Measure-Object -Maximum).Maximum

		# Clear current line and write the stats
		Write-Host "`r" -NoNewline
		Write-Host (" " * ($host.UI.RawUI.WindowSize.Width - 1)) -NoNewline
		Write-Host "`r" -NoNewline
		Write-Host "`r[$currentTime] Avg: $($averagePing -as [int])ms | Min: $($minPing)ms | Max: $($maxPing)ms | Timeouts (last 100): $timeoutCount"

		# Clear next line and write the result
		Write-Host "`r" -NoNewline
		Write-Host (" " * ($host.UI.RawUI.WindowSize.Width - 1)) -NoNewline
		Write-Host "`r" -NoNewline
		Write-Host "`r$result$timeout"

		# After writing, move the cursor up two lines to be in position for the next iteration
		$pos = $host.UI.RawUI.CursorPosition
		$pos.Y -= 2
		$host.UI.RawUI.CursorPosition = $pos

		Start-Sleep -Milliseconds 1000 # Optional: Sleep for 1 second
	}
}

finally {
    # Reset cursor position to where the latest output is:
    $pos = $host.UI.RawUI.CursorPosition
    $pos.Y += 2
    $host.UI.RawUI.CursorPosition = $pos
}