<#
Temp File Cleanup (Safe / Reversible)
PowerShell: 5.1

This script performs a safe cleanup of temp files by moving eligible files
into a quarantine folder instead of permanently deleting them. A manifest is
written for each run so files can be restored later with -Rollback.
#>

[CmdletBinding(DefaultParameterSetName = 'Cleanup')]
param(
    # Section: Cleanup parameters
    # Defines which paths are scanned and how old files must be before they are eligible.
    [Parameter(ParameterSetName = 'Cleanup')]
    [string[]]$Paths = @(
        [System.IO.Path]::GetTempPath(),
        (Join-Path -Path $env:SystemRoot -ChildPath 'Temp')
    ),

    [Parameter(ParameterSetName = 'Cleanup')]
    [ValidateRange(0, 3650)]
    [int]$OlderThanDays = 0,

    [Parameter(ParameterSetName = 'Cleanup')]
    [switch]$DryRun,

    [Parameter(ParameterSetName = 'Cleanup')]
    [string]$QuarantineRoot = (Join-Path -Path $PSScriptRoot -ChildPath 'TempCleanup-Quarantine'),

    [Parameter(ParameterSetName = 'Cleanup')]
    [string]$LogRoot = (Join-Path -Path $PSScriptRoot -ChildPath 'Logs'),

    # Section: Rollback parameters
    # Supports restoring the latest cleanup run or a specific operation ID.
    [Parameter(ParameterSetName = 'Rollback', Mandatory = $true)]
    [switch]$Rollback,

    [Parameter(ParameterSetName = 'Rollback')]
    [string]$OperationId,

    [Parameter(ParameterSetName = 'Rollback')]
    [string]$RollbackManifestPath
)

$ErrorActionPreference = 'Stop'

# Section: Helper functions
# Provides logging, manifest lookup, lock detection, cleanup execution, and rollback.
function New-DirectoryIfMissing {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -Path $Path -ItemType Directory -Force | Out-Null
    }
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

function Get-SafeName {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    return (($Value -replace '^[A-Za-z]:', '') -replace '[\\/:*?""<>|]', '_').Trim('_')
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
        $namedManifest = Join-Path -Path $manifestFolder -ChildPath ('cleanup-manifest-{0}.json' -f $RequestedOperationId)
        if (Test-Path -LiteralPath $namedManifest) {
            return $namedManifest
        }

        return $null
    }

    $latestManifest = Get-ChildItem -Path $manifestFolder -Filter 'cleanup-manifest-*.json' -File |
        Sort-Object -Property LastWriteTime -Descending |
        Select-Object -First 1

    if ($latestManifest) {
        return $latestManifest.FullName
    }

    return $null
}

function New-RunToken {
    return '{0}-{1}' -f (Get-Date -Format 'yyyyMMdd-HHmmss-fff'), $PID
}

function Invoke-Cleanup {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$TargetPaths,

        [Parameter(Mandatory = $true)]
        [int]$AgeInDays,

        [Parameter(Mandatory = $true)]
        [bool]$IsDryRun,

        [Parameter(Mandatory = $true)]
        [string]$QuarantineBase,

        [Parameter(Mandatory = $true)]
        [string]$CurrentOperationId
    )

    $summary = [ordered]@{
        OperationId      = $CurrentOperationId
        Mode             = if ($IsDryRun) { 'DryRun' } else { 'Cleanup' }
        StartedAt        = (Get-Date)
        PathsScanned     = 0
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

    if (-not $IsDryRun) {
        New-DirectoryIfMissing -Path $runQuarantinePath
    }

    foreach ($targetPath in $TargetPaths) {
        if ([string]::IsNullOrWhiteSpace($targetPath)) {
            continue
        }

        $resolvedPath = [Environment]::ExpandEnvironmentVariables($targetPath)
        $summary.PathsScanned++

        if (-not (Test-Path -LiteralPath $resolvedPath)) {
            Write-Log -Level 'WARN' -Message ('Path not found and skipped: {0}' -f $resolvedPath)
            continue
        }

        Write-Log -Level 'INFO' -Message ('Scanning path: {0}' -f $resolvedPath)

        $files = Get-ChildItem -LiteralPath $resolvedPath -File -Recurse -Force -ErrorAction SilentlyContinue |
            Where-Object { $_.LastWriteTime -le $cutoffDate }

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
                    Write-Host ('DRY RUN: would delete {0}' -f $file.FullName)
                    Write-Log -Level 'INFO' -Message ('Dry run candidate: {0}' -f $file.FullName)
                    continue
                }

                $safeRootName = Get-SafeName -Value $resolvedPath
                $destinationFolder = Join-Path -Path $runQuarantinePath -ChildPath $safeRootName
                $destinationPath = Join-Path -Path $destinationFolder -ChildPath $file.Name
                $suffix = 0

                New-DirectoryIfMissing -Path $destinationFolder

                while (Test-Path -LiteralPath $destinationPath) {
                    $suffix++
                    $destinationPath = Join-Path -Path $destinationFolder -ChildPath ('{0}_{1}{2}' -f $file.BaseName, $suffix, $file.Extension)
                }

                Move-Item -LiteralPath $file.FullName -Destination $destinationPath -Force -ErrorAction Stop

                [void]$manifestEntries.Add([PSCustomObject]@{
                    OriginalPath       = $file.FullName
                    QuarantinePath     = $destinationPath
                    LastWriteTimeUtc   = $file.LastWriteTimeUtc
                    Length             = $file.Length
                    Status             = 'Moved'
                    OperationId        = $CurrentOperationId
                    ProcessedAtUtc     = [datetime]::UtcNow
                })

                $summary.FilesMoved++
                Write-Log -Level 'INFO' -Message ('Moved file to quarantine: {0} -> {1}' -f $file.FullName, $destinationPath)
            }
            catch {
                $summary.Errors++
                Write-Log -Level 'ERROR' -Message ('Failed to process file: {0}. Error: {1}' -f $file.FullName, $_.Exception.Message)
            }
        }
    }

    $summary.CompletedAt = Get-Date
    $summary.ManifestEntries = $manifestEntries.Count

    if ((-not $IsDryRun) -and $manifestEntries.Count -gt 0) {
        $manifestFolder = Join-Path -Path $QuarantineBase -ChildPath 'Manifests'
        New-DirectoryIfMissing -Path $manifestFolder
        $manifestPath = Join-Path -Path $manifestFolder -ChildPath ('cleanup-manifest-{0}.json' -f $CurrentOperationId)

        $manifest = [PSCustomObject]@{
            OperationId   = $CurrentOperationId
            Mode          = 'Cleanup'
            QuarantineRun = $runQuarantinePath
            StartedAt     = $summary.StartedAt
            CompletedAt   = $summary.CompletedAt
            OlderThanDays = $AgeInDays
            Paths         = $TargetPaths
            Entries       = $manifestEntries.ToArray()
        }

        $manifest | ConvertTo-Json -Depth 6 | Set-Content -Path $manifestPath -Encoding UTF8
        Write-Log -Level 'INFO' -Message ('Manifest written: {0}' -f $manifestPath)
        $summary.ManifestPath = $manifestPath
    }
    elseif (-not $IsDryRun) {
        Write-Log -Level 'INFO' -Message 'No files were moved, so no rollback manifest was written.'
    }

    return [PSCustomObject]$summary
}

function Invoke-Rollback {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ManifestPath
    )

    $summary = [ordered]@{
        Mode              = 'Rollback'
        ManifestPath      = $ManifestPath
        StartedAt         = Get-Date
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
                Write-Log -Level 'INFO' -Message ('Manifest entry already restored, skipped: {0}' -f $entry.OriginalPath)
                continue
            }

            if (-not (Test-Path -LiteralPath $entry.QuarantinePath)) {
                $summary.FilesMissing++
                Write-Log -Level 'WARN' -Message ('Quarantine file missing, cannot restore: {0}' -f $entry.QuarantinePath)
                continue
            }

            if (Test-Path -LiteralPath $entry.OriginalPath) {
                $summary.FilesAlreadyExist++
                Write-Log -Level 'WARN' -Message ('Original path already exists, restore skipped: {0}' -f $entry.OriginalPath)
                continue
            }

            $parentDirectory = Split-Path -Path $entry.OriginalPath -Parent
            if (-not (Test-Path -LiteralPath $parentDirectory)) {
                New-Item -Path $parentDirectory -ItemType Directory -Force | Out-Null
            }

            Move-Item -LiteralPath $entry.QuarantinePath -Destination $entry.OriginalPath -Force -ErrorAction Stop
            $entry | Add-Member -NotePropertyName Status -NotePropertyValue 'Restored' -Force
            $entry | Add-Member -NotePropertyName RestoredAtUtc -NotePropertyValue ([datetime]::UtcNow) -Force

            $summary.FilesRestored++
            Write-Log -Level 'INFO' -Message ('Restored file: {0} -> {1}' -f $entry.QuarantinePath, $entry.OriginalPath)
        }
        catch {
            $summary.Errors++
            Write-Log -Level 'ERROR' -Message ('Failed to restore file: {0}. Error: {1}' -f $entry.OriginalPath, $_.Exception.Message)
        }
    }

    $manifest | Add-Member -NotePropertyName Entries -NotePropertyValue @($entries) -Force
    $manifest | Add-Member -NotePropertyName RollbackCompletedAt -NotePropertyValue (Get-Date) -Force
    $manifest | ConvertTo-Json -Depth 6 | Set-Content -Path $ManifestPath -Encoding UTF8

    $summary.CompletedAt = Get-Date
    return [PSCustomObject]$summary
}

# Section: Startup and log initialization
# Creates required folders and prepares a timestamped log file for this execution.
New-DirectoryIfMissing -Path $LogRoot
New-DirectoryIfMissing -Path $QuarantineRoot

$timestampToken = New-RunToken
$script:LogFile = Join-Path -Path $LogRoot -ChildPath ('temp-file-cleanup-{0}.log' -f $timestampToken)
New-Item -Path $script:LogFile -ItemType File -Force | Out-Null

Write-Log -Level 'INFO' -Message ('Script started. Parameter set: {0}' -f $PSCmdlet.ParameterSetName)

# Section: Main execution flow
# Runs either cleanup mode or rollback mode, then prints and logs a final summary.
try {
    if ($Rollback) {
        $manifestPath = Get-ManifestPath -Root $QuarantineRoot -RequestedOperationId $OperationId -RequestedManifestPath $RollbackManifestPath

        if (-not $manifestPath) {
            throw 'No rollback manifest could be found for the requested operation.'
        }

        Write-Log -Level 'INFO' -Message ('Rollback requested. Using manifest: {0}' -f $manifestPath)
        $result = Invoke-Rollback -ManifestPath $manifestPath
    }
    else {
        $operationId = New-RunToken
        Write-Log -Level 'INFO' -Message ('Cleanup requested. DryRun={0}; OlderThanDays={1}' -f $DryRun.IsPresent, $OlderThanDays)
        $result = Invoke-Cleanup -TargetPaths $Paths -AgeInDays $OlderThanDays -IsDryRun $DryRun.IsPresent -QuarantineBase $QuarantineRoot -CurrentOperationId $operationId
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