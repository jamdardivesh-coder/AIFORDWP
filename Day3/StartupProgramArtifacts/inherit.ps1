<#
Purpose:
- Collect and display a quick system health snapshot.

Author:
- Unknown (refactored for readability by GitHub Copilot).

How to run:
- Open PowerShell.
- Navigate to this folder.
- Run: .\inherit.ps1

What it reports:
- Computer name and total physical memory.
- Free space on drive C: in GB.
- Top 5 memory-consuming processes.
- Recent System log error events (from the latest 10 events).
- Count of non-special user profiles not used in the last 90 days.

Notes:
- This script is read-only and does not change system settings.
#>

# Read computer system details (for example, name and total physical memory).
$computerSystem = Get-CimInstance Win32_ComputerSystem

# Read free space in bytes from the C: drive.
$freeSpaceBytes = Get-PSDrive C | Select-Object -ExpandProperty Free

# Read all processes, sort by working set memory descending, and keep the top 5.
$topMemoryProcesses = Get-Process | Sort-Object WS -Descending | Select-Object -First 5

# Read the latest 10 events from the System log, then filter to error-level events (Level 2).
$recentSystemErrors = Get-WinEvent -LogName System -MaxEvents 10 | Where-Object { $_.Level -eq 2 }

# Read user profiles and keep only non-special profiles not used in the last 90 days.
$staleUserProfiles = Get-CimInstance Win32_UserProfile | Where-Object {
     -not $_.Special -and $_.LastUseTime -lt (Get-Date).AddDays(-90)
}

# Display the computer name and total physical memory.
Write-Host $computerSystem.Name $computerSystem.TotalPhysicalMemory

# Convert free space bytes to GB, round to 2 decimals, and display it.
Write-Host ([math]::Round($freeSpaceBytes / 1GB, 2)) 'GB free'

# Display each of the top memory-consuming processes with its working set value.
$topMemoryProcesses | ForEach-Object { Write-Host $_.Name $_.WS }

# Display the timestamp and message for each recent System error event.
$recentSystemErrors | ForEach-Object { Write-Host $_.TimeCreated $_.Message }

# If stale profiles exist, display the count.
if ($staleUserProfiles.Count -gt 0) { Write-Host 'Stale profiles:' $staleUserProfiles.Count }