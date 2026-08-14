[CmdletBinding()]
param(
    # Root folder to evaluate for cleanup.
    [Parameter(Mandatory = $true)]
    [string]$TargetPath,

    # Only files older than this many days are eligible. Default 0 means all existing files.
    [int]$OlderThanDays = 0,

    # Dry run lists candidate files and logs planned actions without moving/deleting files.
    [switch]$DryRun,

    # Rollback mode restores files from a previous manifest.
    [switch]$Rollback,

    # Manifest path is required for rollback mode.
    [string]$ManifestPath,

    # Optional log directory. Default is a Logs folder next to this script.
    [string]$LogDirectory = (Join-Path $PSScriptRoot "Logs"),

    # Optional quarantine root. Files are moved here during cleanup to support rollback.
    [string]$QuarantineRoot = (Join-Path $PSScriptRoot "Quarantine")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Region: Utility helpers for timestamping, logging, and path safety.
$runId = Get-Date -Format "yyyyMMdd-HHmmss"
if (-not (Test-Path -Path $LogDirectory)) {
    New-Item -Path $LogDirectory -ItemType Directory -Force | Out-Null
}

$logPath = Join-Path $LogDirectory "cleanup-$runId.log"

function Write-Log {
    param(
        [string]$Level,
        [string]$Message
    )

    $line = "[{0}] [{1}] {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Level.ToUpperInvariant(), $Message
    Add-Content -Path $logPath -Value $line
}

function Test-FileLocked {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    try {
        $stream = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
        $stream.Close()
        return $false
    }
    catch {
        return $true
    }
}

# Region: Summary object used for end-of-run reporting.
$summary = [ordered]@{
    RunId = $runId
    Mode = if ($Rollback) { "Rollback" } elseif ($DryRun) { "DryRun" } else { "Cleanup" }
    TargetPath = $TargetPath
    OlderThanDays = $OlderThanDays
    LogPath = $logPath
    ManifestPath = $null
    FilesScanned = 0
    FilesEligible = 0
    FilesPlanned = 0
    FilesMovedToQuarantine = 0
    FilesRestored = 0
    FilesSkippedLocked = 0
    FilesSkippedAlreadyAbsent = 0
    FilesSkippedDestinationExists = 0
    FileErrors = 0
}

# Region: Validate inputs for the selected mode.
if (-not $Rollback) {
    if (-not (Test-Path -Path $TargetPath)) {
        throw "TargetPath not found: $TargetPath"
    }
    $resolvedTarget = (Resolve-Path -Path $TargetPath).Path
}
else {
    if ([string]::IsNullOrWhiteSpace($ManifestPath)) {
        throw "ManifestPath is required when -Rollback is specified."
    }
    if (-not (Test-Path -Path $ManifestPath)) {
        throw "ManifestPath not found: $ManifestPath"
    }
    $summary.ManifestPath = (Resolve-Path -Path $ManifestPath).Path
}

Write-Log -Level "info" -Message "Starting mode: $($summary.Mode)"

# Region: Rollback logic restores files from a prior manifest, skipping conflicts safely.
if ($Rollback) {
    $manifest = Get-Content -Path $ManifestPath -Raw | ConvertFrom-Json

    foreach ($entry in $manifest.Files) {
        try {
            $stagedPath = $entry.StagedPath
            $originalPath = $entry.OriginalPath

            if (-not (Test-Path -Path $stagedPath)) {
                $summary.FilesSkippedAlreadyAbsent++
                Write-Log -Level "warn" -Message "Staged file missing, cannot restore: $stagedPath"
                continue
            }

            if (Test-Path -Path $originalPath) {
                $summary.FilesSkippedDestinationExists++
                Write-Log -Level "warn" -Message "Destination already exists, skip restore: $originalPath"
                continue
            }

            $destDir = Split-Path -Path $originalPath -Parent
            if (-not (Test-Path -Path $destDir)) {
                New-Item -Path $destDir -ItemType Directory -Force | Out-Null
            }

            Move-Item -Path $stagedPath -Destination $originalPath -Force
            $summary.FilesRestored++
            Write-Log -Level "info" -Message "Restored: $originalPath"
        }
        catch {
            $summary.FileErrors++
            Write-Log -Level "error" -Message "Rollback error for $($entry.OriginalPath): $($_.Exception.Message)"
        }
    }

    Write-Log -Level "info" -Message "Rollback complete."
    $summaryObject = [pscustomobject]$summary
    $summaryObject | ConvertTo-Json -Depth 6
    return
}

# Region: Cleanup mode discovers candidate files by age and handles dry-run or execution.
$cutoff = (Get-Date).AddDays(-1 * $OlderThanDays)
Write-Log -Level "info" -Message "Cutoff timestamp: $cutoff"

$files = Get-ChildItem -Path $resolvedTarget -File -Recurse -ErrorAction Stop
$summary.FilesScanned = $files.Count

$eligible = $files | Where-Object { $_.LastWriteTime -lt $cutoff }
$summary.FilesEligible = $eligible.Count

# Build a deterministic quarantine folder path to support rollback.
$quarantineRunDir = Join-Path $QuarantineRoot $runId
if (-not $DryRun) {
    New-Item -Path $quarantineRunDir -ItemType Directory -Force | Out-Null
}

$manifestEntries = @()

foreach ($file in $eligible) {
    $summary.FilesPlanned++

    # Determine relative path for predictable staging and idempotent behavior.
    $relative = $file.FullName.Substring($resolvedTarget.Length).TrimStart('\\')
    $stagedPath = Join-Path $quarantineRunDir $relative

    if ($DryRun) {
        Write-Output "DRYRUN_DELETE_CANDIDATE: $($file.FullName)"
        Write-Log -Level "info" -Message "DryRun candidate: $($file.FullName)"
        continue
    }

    # Per-file try/catch ensures one error does not stop overall processing.
    try {
        if (Test-FileLocked -Path $file.FullName) {
            $summary.FilesSkippedLocked++
            Write-Log -Level "warn" -Message "Locked file skipped: $($file.FullName)"
            continue
        }

        $stagedDir = Split-Path -Path $stagedPath -Parent
        if (-not (Test-Path -Path $stagedDir)) {
            New-Item -Path $stagedDir -ItemType Directory -Force | Out-Null
        }

        Move-Item -Path $file.FullName -Destination $stagedPath -Force
        $summary.FilesMovedToQuarantine++
        Write-Log -Level "info" -Message "Moved to quarantine: $($file.FullName) -> $stagedPath"

        $manifestEntries += [pscustomobject]@{
            OriginalPath = $file.FullName
            StagedPath = $stagedPath
            LastWriteTime = $file.LastWriteTime
            Length = $file.Length
        }
    }
    catch {
        $summary.FileErrors++
        Write-Log -Level "error" -Message "Cleanup error for $($file.FullName): $($_.Exception.Message)"
    }
}

# Region: Persist manifest for rollback only when actual cleanup moved files.
if (-not $DryRun) {
    $manifest = [pscustomobject]@{
        RunId = $runId
        CreatedAt = Get-Date
        TargetPath = $resolvedTarget
        OlderThanDays = $OlderThanDays
        QuarantinePath = $quarantineRunDir
        Files = $manifestEntries
    }

    $manifestPathOut = Join-Path $LogDirectory "manifest-$runId.json"
    $manifest | ConvertTo-Json -Depth 8 | Set-Content -Path $manifestPathOut -Encoding UTF8
    $summary.ManifestPath = $manifestPathOut
    Write-Log -Level "info" -Message "Manifest written: $manifestPathOut"
}

# Region: Emit final summary for operators and automation consumers.
Write-Log -Level "info" -Message "Run complete. Planned=$($summary.FilesPlanned), Moved=$($summary.FilesMovedToQuarantine), Locked=$($summary.FilesSkippedLocked), Errors=$($summary.FileErrors)"

$summaryObject = [pscustomobject]$summary
$summaryObject | ConvertTo-Json -Depth 6
