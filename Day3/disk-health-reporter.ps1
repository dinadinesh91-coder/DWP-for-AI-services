<#
Disk Health Reporter (Read-Only Endpoint Checks)
PowerShell: 5.1

This script reports disk health and optimization status without running any
optimization actions. It never runs defragmentation. Optional cleanup logic is
limited to script-generated report artifacts under Day3\Logs.
#>

[CmdletBinding(DefaultParameterSetName = 'Report')]
param(
    # Section: Reporting parameters
    # Controls which drives are reported and where report/log artifacts are written.
    [Parameter(ParameterSetName = 'Report')]
    [string[]]$DriveLetters,

    [Parameter(ParameterSetName = 'Report')]
    [ValidateRange(0, 3650)]
    [int]$OlderThanDays = 0,

    [Parameter(ParameterSetName = 'Report')]
    [switch]$DryRun,

    [Parameter(ParameterSetName = 'Report')]
    [switch]$CleanupOldReports,

    [Parameter(ParameterSetName = 'Report')]
    [string]$ReportRoot = (Join-Path -Path $PSScriptRoot -ChildPath 'Logs\DiskHealthReports'),

    [Parameter(ParameterSetName = 'Report')]
    [string]$QuarantineRoot = (Join-Path -Path $PSScriptRoot -ChildPath 'Logs\DiskHealthReports-Quarantine'),

    [Parameter(ParameterSetName = 'Report')]
    [string]$LogRoot = (Join-Path -Path $PSScriptRoot -ChildPath 'Logs'),

    # Section: Rollback parameters
    # Restores previously quarantined report artifacts (script output only).
    [Parameter(ParameterSetName = 'Rollback', Mandatory = $true)]
    [switch]$Rollback,

    [Parameter(ParameterSetName = 'Rollback')]
    [string]$OperationId,

    [Parameter(ParameterSetName = 'Rollback')]
    [string]$RollbackManifestPath
)

$ErrorActionPreference = 'Stop'

# Section: Helper functions
# Utility functions for folder creation, logging, lock checks, and manifest handling.
function New-DirectoryIfMissing {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -Path $Path -ItemType Directory -Force | Out-Null
    }
}

function New-RunToken {
    return '{0}-{1}' -f (Get-Date -Format 'yyyyMMdd-HHmmss-fff'), $PID
}

function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $true)]
        [string]$Level
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $entry = '[{0}] [{1}] {2}' -f $timestamp, $Level.ToUpperInvariant(), $Message
    Add-Content -Path $script:LogFile -Value $entry
    Write-Host $entry
}

function Test-FileLocked {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $stream = $null
    try {
        $stream = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
        return $false
    }
    catch [System.IO.IOException] {
        return $true
    }
    finally {
        if ($stream) {
            $stream.Dispose()
        }
    }
}

function Get-ManifestPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Root,

        [string]$RequestedOperationId,

        [string]$RequestedManifestPath
    )

    if ($RequestedManifestPath) {
        return $RequestedManifestPath
    }

    $manifestFolder = Join-Path -Path $Root -ChildPath 'Manifests'
    if (-not (Test-Path -LiteralPath $manifestFolder)) {
        return $null
    }

    if ($RequestedOperationId) {
        $namedManifest = Join-Path -Path $manifestFolder -ChildPath ('report-cleanup-manifest-{0}.json' -f $RequestedOperationId)
        if (Test-Path -LiteralPath $namedManifest) {
            return $namedManifest
        }

        return $null
    }

    $latestManifest = Get-ChildItem -Path $manifestFolder -Filter 'report-cleanup-manifest-*.json' -File |
        Sort-Object -Property LastWriteTime -Descending |
        Select-Object -First 1

    if ($latestManifest) {
        return $latestManifest.FullName
    }

    return $null
}

# Section: Data collection
# Collects logical disk, physical disk, and optimization schedule status in read-only mode.
function Get-DriveReport {
    param(
        [string[]]$RequestedDriveLetters
    )

    $logicalDisks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter 'DriveType = 3'

    if ($RequestedDriveLetters -and $RequestedDriveLetters.Count -gt 0) {
        $normalized = @($RequestedDriveLetters | ForEach-Object { $_.TrimEnd(':').ToUpperInvariant() })
        $logicalDisks = $logicalDisks | Where-Object {
            $drive = $_.DeviceID.TrimEnd(':').ToUpperInvariant()
            $normalized -contains $drive
        }
    }

    $driveReports = New-Object System.Collections.ArrayList

    foreach ($disk in $logicalDisks) {
        try {
            $sizeBytes = [double]$disk.Size
            $freeBytes = [double]$disk.FreeSpace
            $usedBytes = $sizeBytes - $freeBytes
            $freePercent = if ($sizeBytes -gt 0) { [math]::Round(($freeBytes / $sizeBytes) * 100, 2) } else { 0 }

            [void]$driveReports.Add([PSCustomObject]@{
                DriveLetter   = $disk.DeviceID
                VolumeName    = $disk.VolumeName
                FileSystem    = $disk.FileSystem
                SizeGB        = [math]::Round($sizeBytes / 1GB, 2)
                UsedGB        = [math]::Round($usedBytes / 1GB, 2)
                FreeGB        = [math]::Round($freeBytes / 1GB, 2)
                FreePercent   = $freePercent
                VolumeStatus  = $disk.Status
            })

            Write-Log -Level 'INFO' -Message ('Collected logical disk status for {0}' -f $disk.DeviceID)
        }
        catch {
            Write-Log -Level 'ERROR' -Message ('Failed to collect logical disk status for {0}. Error: {1}' -f $disk.DeviceID, $_.Exception.Message)
        }
    }

    return $driveReports
}

function Get-PhysicalDiskReport {
    $physicalReports = New-Object System.Collections.ArrayList

    try {
        $physicalDisks = Get-PhysicalDisk -ErrorAction Stop

        foreach ($disk in $physicalDisks) {
            try {
                [void]$physicalReports.Add([PSCustomObject]@{
                    FriendlyName      = $disk.FriendlyName
                    MediaType         = $disk.MediaType
                    HealthStatus      = $disk.HealthStatus
                    OperationalStatus = ($disk.OperationalStatus -join ', ')
                    SizeGB            = [math]::Round(([double]$disk.Size / 1GB), 2)
                })

                Write-Log -Level 'INFO' -Message ('Collected physical disk status for {0}' -f $disk.FriendlyName)
            }
            catch {
                Write-Log -Level 'ERROR' -Message ('Failed to process physical disk entry. Error: {0}' -f $_.Exception.Message)
            }
        }
    }
    catch {
        Write-Log -Level 'WARN' -Message ('Get-PhysicalDisk unavailable. Falling back to Win32_DiskDrive. Error: {0}' -f $_.Exception.Message)

        $fallbackDisks = Get-CimInstance -ClassName Win32_DiskDrive
        foreach ($disk in $fallbackDisks) {
            try {
                [void]$physicalReports.Add([PSCustomObject]@{
                    FriendlyName      = $disk.Model
                    MediaType         = $disk.MediaType
                    HealthStatus      = $disk.Status
                    OperationalStatus = $disk.Status
                    SizeGB            = [math]::Round(([double]$disk.Size / 1GB), 2)
                })

                Write-Log -Level 'INFO' -Message ('Collected fallback physical disk status for {0}' -f $disk.Model)
            }
            catch {
                Write-Log -Level 'ERROR' -Message ('Failed to process fallback physical disk entry. Error: {0}' -f $_.Exception.Message)
            }
        }
    }

    return $physicalReports
}

function Get-OptimizationStatus {
    $scheduledTaskState = 'Unknown'
    $lastRunTime = $null
    $nextRunTime = $null

    try {
        $task = Get-ScheduledTask -TaskPath '\Microsoft\Windows\Defrag\' -TaskName 'ScheduledDefrag' -ErrorAction Stop
        $taskInfo = Get-ScheduledTaskInfo -TaskName 'ScheduledDefrag' -TaskPath '\Microsoft\Windows\Defrag\' -ErrorAction Stop

        $scheduledTaskState = $task.State
        $lastRunTime = $taskInfo.LastRunTime
        $nextRunTime = $taskInfo.NextRunTime
        Write-Log -Level 'INFO' -Message 'Collected ScheduledDefrag task status.'
    }
    catch {
        Write-Log -Level 'WARN' -Message ('Unable to query ScheduledDefrag task. Error: {0}' -f $_.Exception.Message)
    }

    $serviceStatus = 'Unknown'
    try {
        $defragService = Get-Service -Name 'defragsvc' -ErrorAction Stop
        $serviceStatus = $defragService.Status
        Write-Log -Level 'INFO' -Message 'Collected defragsvc service status.'
    }
    catch {
        Write-Log -Level 'WARN' -Message ('Unable to query defragsvc service. Error: {0}' -f $_.Exception.Message)
    }

    $recentEvents = New-Object System.Collections.ArrayList
    try {
        $events = Get-WinEvent -FilterHashtable @{
            LogName = 'Application'
            ProviderName = 'Microsoft-Windows-Defrag'
            StartTime = (Get-Date).AddDays(-30)
        } -MaxEvents 10 -ErrorAction Stop

        foreach ($optimizationEvent in $events) {
            try {
                [void]$recentEvents.Add([PSCustomObject]@{
                    TimeCreated = $optimizationEvent.TimeCreated
                    Id          = $optimizationEvent.Id
                    Level       = $optimizationEvent.LevelDisplayName
                    Message     = ($optimizationEvent.Message -replace "`r`n", ' ')
                })
            }
            catch {
                Write-Log -Level 'ERROR' -Message ('Failed to process optimization event entry. Error: {0}' -f $_.Exception.Message)
            }
        }

        Write-Log -Level 'INFO' -Message ('Collected {0} optimization-related event(s).' -f $recentEvents.Count)
    }
    catch {
        Write-Log -Level 'WARN' -Message ('Unable to query optimization events. Error: {0}' -f $_.Exception.Message)
    }

    return [PSCustomObject]@{
        ScheduledDefragTaskState = $scheduledTaskState
        LastRunTime              = $lastRunTime
        NextRunTime              = $nextRunTime
        DefragServiceStatus      = $serviceStatus
        RecentOptimizationEvents = $recentEvents
    }
}

# Section: Artifact cleanup (optional)
# Safely handles old script-generated reports only. It does not touch endpoint user/system files.
function Invoke-ReportArtifactCleanup {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetRoot,

        [Parameter(Mandatory = $true)]
        [int]$AgeInDays,

        [Parameter(Mandatory = $true)]
        [bool]$IsDryRun,

        [Parameter(Mandatory = $true)]
        [string]$QuarantineBase,

        [Parameter(Mandatory = $true)]
        [string]$CurrentOperationId,

        [Parameter(Mandatory = $true)]
        [string]$ExcludeFilePath
    )

    $summary = [ordered]@{
        CleanupMode      = if ($IsDryRun) { 'DryRun' } else { 'Cleanup' }
        FilesEnumerated  = 0
        FilesEligible    = 0
        FilesMoved       = 0
        FilesSkippedLock = 0
        FilesMissing     = 0
        Errors           = 0
        ManifestPath     = $null
    }

    $manifestEntries = New-Object System.Collections.ArrayList
    $cutoffDate = (Get-Date).AddDays(-1 * $AgeInDays)
    $runQuarantinePath = Join-Path -Path $QuarantineBase -ChildPath $CurrentOperationId

    if (-not (Test-Path -LiteralPath $TargetRoot)) {
        Write-Log -Level 'INFO' -Message ('Cleanup root does not exist. Skipping cleanup: {0}' -f $TargetRoot)
        return [PSCustomObject]$summary
    }

    if (-not $IsDryRun) {
        New-DirectoryIfMissing -Path $runQuarantinePath
    }

    $files = Get-ChildItem -Path $TargetRoot -File -Recurse -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -le $cutoffDate -and $_.FullName -ne $ExcludeFilePath }

    foreach ($file in $files) {
        $summary.FilesEnumerated++

        try {
            if (-not (Test-Path -LiteralPath $file.FullName)) {
                $summary.FilesMissing++
                Write-Log -Level 'WARN' -Message ('File missing before processing: {0}' -f $file.FullName)
                continue
            }

            $summary.FilesEligible++

            if (Test-FileLocked -Path $file.FullName) {
                $summary.FilesSkippedLock++
                Write-Log -Level 'WARN' -Message ('Locked file skipped: {0}' -f $file.FullName)
                continue
            }

            if ($IsDryRun) {
                Write-Host ('DRY RUN: would delete report artifact {0}' -f $file.FullName)
                Write-Log -Level 'INFO' -Message ('Dry run candidate: {0}' -f $file.FullName)
                continue
            }

            $destinationFolder = Join-Path -Path $runQuarantinePath -ChildPath ((Split-Path -Path $file.DirectoryName -Leaf) -replace '[\\/:*?""<>|]', '_')
            $destinationPath = Join-Path -Path $destinationFolder -ChildPath $file.Name
            $suffix = 0

            New-DirectoryIfMissing -Path $destinationFolder

            while (Test-Path -LiteralPath $destinationPath) {
                $suffix++
                $destinationPath = Join-Path -Path $destinationFolder -ChildPath ('{0}_{1}{2}' -f $file.BaseName, $suffix, $file.Extension)
            }

            Move-Item -LiteralPath $file.FullName -Destination $destinationPath -Force -ErrorAction Stop

            [void]$manifestEntries.Add([PSCustomObject]@{
                OriginalPath   = $file.FullName
                QuarantinePath = $destinationPath
                Status         = 'Moved'
                OperationId    = $CurrentOperationId
                ProcessedAtUtc = [datetime]::UtcNow
            })

            $summary.FilesMoved++
            Write-Log -Level 'INFO' -Message ('Moved report artifact to quarantine: {0} -> {1}' -f $file.FullName, $destinationPath)
        }
        catch {
            $summary.Errors++
            Write-Log -Level 'ERROR' -Message ('Failed to process report artifact: {0}. Error: {1}' -f $file.FullName, $_.Exception.Message)
        }
    }

    if ((-not $IsDryRun) -and $manifestEntries.Count -gt 0) {
        $manifestFolder = Join-Path -Path $QuarantineBase -ChildPath 'Manifests'
        New-DirectoryIfMissing -Path $manifestFolder

        $manifestPath = Join-Path -Path $manifestFolder -ChildPath ('report-cleanup-manifest-{0}.json' -f $CurrentOperationId)

        $manifest = [PSCustomObject]@{
            OperationId = $CurrentOperationId
            Mode        = 'Cleanup'
            StartedAt   = (Get-Date)
            OlderThanDays = $AgeInDays
            TargetRoot  = $TargetRoot
            Entries     = $manifestEntries.ToArray()
        }

        $manifest | ConvertTo-Json -Depth 6 | Set-Content -Path $manifestPath -Encoding UTF8
        $summary.ManifestPath = $manifestPath
        Write-Log -Level 'INFO' -Message ('Cleanup manifest written: {0}' -f $manifestPath)
    }

    return [PSCustomObject]$summary
}

function Invoke-ReportRollback {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ManifestPath
    )

    $summary = [ordered]@{
        Mode              = 'Rollback'
        ManifestPath      = $ManifestPath
        EntriesRead       = 0
        FilesRestored     = 0
        FilesAlreadyExist = 0
        FilesMissing      = 0
        Errors            = 0
    }

    if (-not (Test-Path -LiteralPath $ManifestPath)) {
        throw ('Rollback manifest not found: {0}' -f $ManifestPath)
    }

    $manifest = Get-Content -Path $ManifestPath -Raw | ConvertFrom-Json
    $entries = @($manifest.Entries)
    $summary.EntriesRead = $entries.Count

    foreach ($entry in $entries) {
        try {
            if ($entry.Status -eq 'Restored') {
                Write-Log -Level 'INFO' -Message ('Already restored, skipping entry: {0}' -f $entry.OriginalPath)
                continue
            }

            if (-not (Test-Path -LiteralPath $entry.QuarantinePath)) {
                $summary.FilesMissing++
                Write-Log -Level 'WARN' -Message ('Quarantine artifact missing: {0}' -f $entry.QuarantinePath)
                continue
            }

            if (Test-Path -LiteralPath $entry.OriginalPath) {
                $summary.FilesAlreadyExist++
                Write-Log -Level 'WARN' -Message ('Original artifact already exists, skipping: {0}' -f $entry.OriginalPath)
                continue
            }

            $parent = Split-Path -Path $entry.OriginalPath -Parent
            if (-not (Test-Path -LiteralPath $parent)) {
                New-Item -Path $parent -ItemType Directory -Force | Out-Null
            }

            Move-Item -LiteralPath $entry.QuarantinePath -Destination $entry.OriginalPath -Force -ErrorAction Stop
            $entry | Add-Member -NotePropertyName Status -NotePropertyValue 'Restored' -Force
            $entry | Add-Member -NotePropertyName RestoredAtUtc -NotePropertyValue ([datetime]::UtcNow) -Force

            $summary.FilesRestored++
            Write-Log -Level 'INFO' -Message ('Restored artifact: {0} -> {1}' -f $entry.QuarantinePath, $entry.OriginalPath)
        }
        catch {
            $summary.Errors++
            Write-Log -Level 'ERROR' -Message ('Failed to restore artifact: {0}. Error: {1}' -f $entry.OriginalPath, $_.Exception.Message)
        }
    }

    $manifest | Add-Member -NotePropertyName Entries -NotePropertyValue @($entries) -Force
    $manifest | Add-Member -NotePropertyName RollbackCompletedAt -NotePropertyValue (Get-Date) -Force
    $manifest | ConvertTo-Json -Depth 6 | Set-Content -Path $ManifestPath -Encoding UTF8

    return [PSCustomObject]$summary
}

# Section: Startup initialization
# Creates folders and sets up timestamped logging for the current execution.
New-DirectoryIfMissing -Path $LogRoot
New-DirectoryIfMissing -Path $ReportRoot
New-DirectoryIfMissing -Path $QuarantineRoot

$runToken = New-RunToken
$script:LogFile = Join-Path -Path $LogRoot -ChildPath ('disk-health-reporter-{0}.log' -f $runToken)
New-Item -Path $script:LogFile -ItemType File -Force | Out-Null

Write-Log -Level 'INFO' -Message ('Script started. Parameter set: {0}' -f $PSCmdlet.ParameterSetName)
Write-Log -Level 'INFO' -Message 'Read-only guarantee: no optimization actions are executed by this script.'

# Section: Main execution flow
# Runs report mode or rollback mode, then writes final summary to console and log.
try {
    if ($Rollback) {
        $manifestPath = Get-ManifestPath -Root $QuarantineRoot -RequestedOperationId $OperationId -RequestedManifestPath $RollbackManifestPath
        if (-not $manifestPath) {
            throw 'No rollback manifest could be found for the requested operation.'
        }

        Write-Log -Level 'INFO' -Message ('Rollback requested. Using manifest: {0}' -f $manifestPath)
        $result = Invoke-ReportRollback -ManifestPath $manifestPath
    }
    else {
        $logical = Get-DriveReport -RequestedDriveLetters $DriveLetters
        $physical = Get-PhysicalDiskReport
        $optimization = Get-OptimizationStatus

        $report = [PSCustomObject]@{
            GeneratedAt   = (Get-Date)
            ComputerName  = $env:COMPUTERNAME
            DriveFilter   = if ($DriveLetters) { $DriveLetters } else { @('All fixed drives') }
            LogicalDisks  = $logical
            PhysicalDisks = $physical
            Optimization  = $optimization
        }

        $reportPath = Join-Path -Path $ReportRoot -ChildPath ('disk-health-report-{0}.json' -f $runToken)
        $report | ConvertTo-Json -Depth 8 | Set-Content -Path $reportPath -Encoding UTF8
        Write-Log -Level 'INFO' -Message ('Report written: {0}' -f $reportPath)

        $cleanupSummary = [PSCustomObject]@{}
        if ($CleanupOldReports) {
            Write-Log -Level 'INFO' -Message ('Cleanup requested. DryRun={0}; OlderThanDays={1}' -f $DryRun.IsPresent, $OlderThanDays)
            $cleanupSummary = Invoke-ReportArtifactCleanup -TargetRoot $ReportRoot -AgeInDays $OlderThanDays -IsDryRun $DryRun.IsPresent -QuarantineBase $QuarantineRoot -CurrentOperationId $runToken -ExcludeFilePath $reportPath
        }
        else {
            Write-Log -Level 'INFO' -Message 'CleanupOldReports not selected. No file cleanup performed.'
        }

        $result = [PSCustomObject]@{
            Mode                   = 'Report'
            ReportPath             = $reportPath
            LogicalDiskCount       = @($logical).Count
            PhysicalDiskCount      = @($physical).Count
            OptimizationEventCount = @($optimization.RecentOptimizationEvents).Count
            CleanupEnabled         = $CleanupOldReports.IsPresent
            CleanupSummary         = $cleanupSummary
        }
    }

    Write-Host ''
    Write-Host 'Summary'
    Write-Host '-------'
    $result.PSObject.Properties | ForEach-Object {
        Write-Host ('{0}: {1}' -f $_.Name, $_.Value)
    }

    Write-Log -Level 'INFO' -Message 'Execution summary follows.'
    $result.PSObject.Properties | ForEach-Object {
        Write-Log -Level 'INFO' -Message ('Summary {0}: {1}' -f $_.Name, $_.Value)
    }
}
catch {
    Write-Log -Level 'ERROR' -Message ('Script failed: {0}' -f $_.Exception.Message)
    throw
}
finally {
    Write-Log -Level 'INFO' -Message 'Script completed.'
}
