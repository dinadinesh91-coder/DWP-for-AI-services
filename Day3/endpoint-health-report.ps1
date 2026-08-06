<#
Endpoint Health Report (Read-Only)
PowerShell: 5.1

VERIFY BEFORE RUNNING:
1. Internet speed check uses outbound HTTPS to https://speed.hetzner.de/1MB.bin.
   Confirm this URL is allowed by your network/security policy.
2. Reading some data (System event log, update history, Defender service state)
   may require elevated permissions depending on endpoint hardening.
3. "Users logged in" is based on interactive/remote-interactive sessions (LogonType 2 and 10).
   Confirm this matches your reporting requirement.
4. CPU top process list is sampled from current process CPU totals and may vary by timing.
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'SilentlyContinue'

# Build an ordered report object for predictable output ordering.
$report = [ordered]@{}

# Section: System uptime
# Calculates uptime using Win32_OperatingSystem last boot time and current time.
$os = Get-CimInstance -ClassName Win32_OperatingSystem
$lastBoot = $null

if ($os -and $os.LastBootUpTime) {
    if ($os.LastBootUpTime -is [datetime]) {
        $lastBoot = $os.LastBootUpTime
    } else {
        try {
            $lastBoot = [Management.ManagementDateTimeConverter]::ToDateTime([string]$os.LastBootUpTime)
        }
        catch {
            $lastBoot = $null
        }
    }
}

# Fallback for endpoints where CIM value is unavailable or unparsable.
if (-not $lastBoot) {
    $wmiOs = Get-WmiObject -Class Win32_OperatingSystem
    if ($wmiOs -and $wmiOs.LastBootUpTime) {
        try {
            $lastBoot = $wmiOs.ConvertToDateTime($wmiOs.LastBootUpTime)
        }
        catch {
            $lastBoot = $null
        }
    }
}

if ($lastBoot) {
    $uptime = (Get-Date) - $lastBoot
    $report['System Uptime'] = [PSCustomObject]@{
        LastBootTime = $lastBoot
        UptimeDays   = [Math]::Round($uptime.TotalDays, 2)
        Uptime       = ('{0}d {1}h {2}m' -f $uptime.Days, $uptime.Hours, $uptime.Minutes)
    }
} else {
    $report['System Uptime'] = [PSCustomObject]@{
        LastBootTime = $null
        UptimeDays   = $null
        Uptime       = 'to confirm (unable to read LastBootUpTime)'
    }
}

# Section: Free disk space
# Lists local fixed disks with total size and free space in GB.
$disks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType = 3" |
    Select-Object DeviceID,
                  @{Name='SizeGB';Expression={[Math]::Round($_.Size / 1GB, 2)}},
                  @{Name='FreeGB';Expression={[Math]::Round($_.FreeSpace / 1GB, 2)}},
                  @{Name='FreePercent';Expression={if ($_.Size -gt 0) {[Math]::Round(($_.FreeSpace / $_.Size) * 100, 2)} else {$null}}}
$report['Free Disk Space'] = $disks

# Section: Pending reboot status
# Checks common registry indicators that Windows reboot is pending.
$pendingRebootChecks = [ordered]@{
    'ComponentBasedServicing\RebootPending' = Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending'
    'WindowsUpdate\Auto Update\RebootRequired' = Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'
    'Session Manager\PendingFileRenameOperations' = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -Name 'PendingFileRenameOperations' -ErrorAction SilentlyContinue) -ne $null
}
$report['Pending Reboot'] = [PSCustomObject]@{
    IsPending = ($pendingRebootChecks.Values -contains $true)
    Checks    = $pendingRebootChecks
}

# Section: Top 5 processes by memory (Working Set)
# Ranks running processes by WorkingSet64 and returns top 5.
# Enriches each process with executable description and hosted services (if any).
$servicesByPid = @{}
Get-CimInstance -ClassName Win32_Service -Filter "ProcessId > 0" | ForEach-Object {
    $pid = [int]$_.ProcessId
    if (-not $servicesByPid.ContainsKey($pid)) {
        $servicesByPid[$pid] = New-Object System.Collections.Generic.List[string]
    }
    $servicesByPid[$pid].Add($_.Name)
}

$topMemory = Get-Process |
    Sort-Object -Property WorkingSet64 -Descending |
    Select-Object -First 5 |
    ForEach-Object {
        # Prefer Get-Process description (matches Task Manager style); fallback to file metadata.
        $procDescription = $_.Description
        if ([string]::IsNullOrWhiteSpace($procDescription) -and $_.Path) {
            try {
                $procDescription = (Get-Item -Path $_.Path).VersionInfo.FileDescription
            }
            catch {
                $procDescription = $null
            }
        }

        $svcNames = if ($servicesByPid.ContainsKey([int]$_.Id)) {
            ($servicesByPid[[int]$_.Id] | Sort-Object -Unique) -join ', '
        } else {
            '-'
        }

        [PSCustomObject]@{
            Name          = $_.Name
            Id            = $_.Id
            Description   = if ([string]::IsNullOrWhiteSpace($procDescription)) { 'to confirm' } else { $procDescription }
            Services      = $svcNames
            WorkingSetMB  = [Math]::Round($_.WorkingSet64 / 1MB, 2)
            CPUSeconds    = [Math]::Round($_.CPU, 2)
        }
    }
$report['Top 5 Processes by Memory'] = $topMemory

# Section: Top 5 processes by CPU
# Ranks running processes by cumulative CPU time and returns top 5.
# Uses the same process description and hosted service mapping as above.
$topCpu = Get-Process |
    Sort-Object -Property CPU -Descending |
    Select-Object -First 5 |
    ForEach-Object {
        # Prefer Get-Process description (matches Task Manager style); fallback to file metadata.
        $procDescription = $_.Description
        if ([string]::IsNullOrWhiteSpace($procDescription) -and $_.Path) {
            try {
                $procDescription = (Get-Item -Path $_.Path).VersionInfo.FileDescription
            }
            catch {
                $procDescription = $null
            }
        }

        $svcNames = if ($servicesByPid.ContainsKey([int]$_.Id)) {
            ($servicesByPid[[int]$_.Id] | Sort-Object -Unique) -join ', '
        } else {
            '-'
        }

        [PSCustomObject]@{
            Name          = $_.Name
            Id            = $_.Id
            Description   = if ([string]::IsNullOrWhiteSpace($procDescription)) { 'to confirm' } else { $procDescription }
            Services      = $svcNames
            CPUSeconds    = [Math]::Round($_.CPU, 2)
            WorkingSetMB  = [Math]::Round($_.WorkingSet64 / 1MB, 2)
        }
    }
$report['Top 5 Processes by CPU'] = $topCpu

# Section: Last 5 system log errors
# Reads the most recent 5 Error-level events from the System event log.
$lastSystemErrors = Get-WinEvent -FilterHashtable @{LogName='System'; Level=2} -MaxEvents 5 |
    Select-Object TimeCreated, Id, ProviderName, Message
$report['Last 5 System Log Errors'] = $lastSystemErrors

# Section: Internet speed (approximate)
# Estimates download throughput by timing an HTTPS request and calculating Mbps.
# This is an approximation and depends on endpoint path, proxy, and server conditions.
$speedUrls = @(
    'https://speed.hetzner.de/1MB.bin',
    'https://speedtest.tele2.net/1MB.zip',
    'https://proof.ovh.net/files/1Mb.dat',
    'https://www.msftconnecttest.com/connecttest.txt'
)

# Use TLS 1.2 for compatibility with modern HTTPS endpoints.
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$internetSpeed = [PSCustomObject]@{
    TestUrl   = ($speedUrls -join ', ')
    Status    = 'Not tested'
    SizeBytes = $null
    Seconds   = $null
    Mbps      = $null
    Note      = 'Approximate download speed from single request.'
}

$attemptErrors = @()
$speedSuccess = $false

foreach ($speedUrl in $speedUrls) {
    try {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $resp = Invoke-WebRequest -Uri $speedUrl -UseBasicParsing -TimeoutSec 20
        $sw.Stop()

        $bytes = 0
        if ($resp.RawContentStream -and $resp.RawContentStream.Length -gt 0) {
            $bytes = [double]$resp.RawContentStream.Length
        } elseif ($resp.Content) {
            $bytes = [double]([System.Text.Encoding]::UTF8.GetByteCount($resp.Content))
        }

        if ($bytes -gt 0 -and $sw.Elapsed.TotalSeconds -gt 0) {
            $mbps = [Math]::Round((($bytes * 8) / 1MB) / $sw.Elapsed.TotalSeconds, 2)
            $internetSpeed = [PSCustomObject]@{
                TestUrl   = $speedUrl
                Status    = 'Success'
                SizeBytes = [int64]$bytes
                Seconds   = [Math]::Round($sw.Elapsed.TotalSeconds, 3)
                Mbps      = $mbps
                Note      = 'Approximate single-request download throughput.'
            }
            $speedSuccess = $true
            break
        }

        $attemptErrors += "${speedUrl}: no content length measured"
    }
    catch {
        $attemptErrors += "${speedUrl}: $($_.Exception.Message)"
    }
}

if (-not $speedSuccess) {
    $internetSpeed.Status = 'Failed'
    $internetSpeed.Note = "Speed check failed on all test URLs (to confirm DNS/proxy/firewall): $($attemptErrors -join '; ')"
}
$report['Internet Speed'] = $internetSpeed

# Section: Microsoft Defender service status
# Checks whether the WinDefend service is present and currently running.
$defenderSvc = Get-Service -Name 'WinDefend' -ErrorAction SilentlyContinue
if ($defenderSvc) {
    $report['Microsoft Defender Service'] = [PSCustomObject]@{
        ServiceName = $defenderSvc.Name
        DisplayName = $defenderSvc.DisplayName
        Status      = [string]$defenderSvc.Status
        IsRunning   = ($defenderSvc.Status -eq 'Running')
    }
} else {
    $report['Microsoft Defender Service'] = [PSCustomObject]@{
        ServiceName = 'WinDefend'
        Status      = 'NotFound'
        IsRunning   = $false
    }
}

# Section: Number of users logged in
# Counts unique users in interactive and remote-interactive logon sessions.
$interactiveUsers = @()
try {
    $sessions = Get-CimInstance -ClassName Win32_LogonSession -Filter "LogonType = 2 OR LogonType = 10"
    foreach ($session in $sessions) {
        $links = Get-CimAssociatedInstance -InputObject $session -Association Win32_LoggedOnUser
        foreach ($link in $links) {
            if ($link.Domain -and $link.Name) {
                $interactiveUsers += ('{0}\{1}' -f $link.Domain, $link.Name)
            }
        }
    }
    $interactiveUsers = $interactiveUsers | Sort-Object -Unique
}
catch {
    # Keep default empty list if session query fails.
}

$report['Users Logged In'] = [PSCustomObject]@{
    Count = $interactiveUsers.Count
    Users = $interactiveUsers
}

# Section: Last Windows Update time
# Reads the most recent successful Windows Update Client install event from System log.
$lastUpdateEvent = Get-WinEvent -FilterHashtable @{LogName='System'; ProviderName='Microsoft-Windows-WindowsUpdateClient'; Id=19} -MaxEvents 1 |
    Select-Object -First 1 TimeCreated, Id, ProviderName, Message

if ($lastUpdateEvent) {
    $report['Last Windows Update'] = $lastUpdateEvent
} else {
    $report['Last Windows Update'] = [PSCustomObject]@{
        TimeCreated  = $null
        ProviderName = 'Microsoft-Windows-WindowsUpdateClient'
        Id           = 19
        Message      = 'No Event ID 19 found in System log (to confirm update channel/log retention).'
    }
}

# Output section
# Displays report in a readable console format and also emits raw object for reuse.
Write-Host "`n=== Endpoint Health Report (Read-Only) ===`n"

foreach ($key in $report.Keys) {
    Write-Host "--- $key ---"
    $value = $report[$key]
    if ($value -is [System.Collections.IEnumerable] -and -not ($value -is [string]) -and -not ($value -is [hashtable]) -and -not ($value -is [PSCustomObject])) {
        $value | Format-Table -AutoSize
    }
    elseif ($value -is [hashtable]) {
        $value.GetEnumerator() | Sort-Object Name | Format-Table -AutoSize
    }
    else {
        $value | Format-List
    }
    Write-Host ""
}

# Emit structured object at the end for optional export/pipeline use.
[PSCustomObject]$report
