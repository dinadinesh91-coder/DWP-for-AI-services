
<#
Purpose:
Collect a quick endpoint snapshot: computer identity, C: free space,
top memory-consuming processes, recent System error events, and stale user profiles.

Author:
DWP Engineer

PowerShell Version:
5.1

How to run:
1. Open PowerShell.
2. Navigate to the script folder.
3. Run: .\inheret.ps1
#>

# Get general computer system details (for example, name and total physical memory).
$computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem

# Get free space (in bytes) from drive C.
$freeSpaceBytes = Get-PSDrive -Name C | Select-Object -ExpandProperty Free

# Get the top 5 running processes by working set memory usage.
$topMemoryProcesses = Get-Process | Sort-Object -Property WS -Descending | Select-Object -First 5

# Get the latest 10 System log entries and keep only error-level events (Level 2).
$systemErrorEvents = Get-WinEvent -LogName System -MaxEvents 10 | Where-Object { $_.Level -eq 2 }

# Get user profiles that are not special/system profiles and have not been used in the last 90 days.
$staleUserProfiles = Get-CimInstance -ClassName Win32_UserProfile | Where-Object {
	-not $_.Special -and $_.LastUseTime -lt (Get-Date).AddDays(-90)
}

# Print computer name and total physical memory.
Write-Host $computerSystem.Name $computerSystem.TotalPhysicalMemory

# Print free space on C: converted from bytes to GB with 2 decimal places.
Write-Host ([math]::Round($freeSpaceBytes / 1GB, 2)) 'GB free'

# Print each top process name and its working set memory value.
$topMemoryProcesses | ForEach-Object { Write-Host $_.Name $_.WS }

# Print the timestamp and message for each selected System error event.
$systemErrorEvents | ForEach-Object { Write-Host $_.TimeCreated $_.Message }

# Print stale profile count when at least one stale profile is found.
if ($staleUserProfiles.Count -gt 0) { Write-Host 'Stale profiles:' $staleUserProfiles.Count }