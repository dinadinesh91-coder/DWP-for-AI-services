# Temp File Cleanup Script

This document explains how to use the safe temp cleanup script in Day3.

## Purpose

The script scans temp locations for files older than a configurable age and safely removes them by moving them into a quarantine folder. Because files are quarantined instead of permanently deleted, the script supports rollback.

Script path:

- `Day3\temp-file-cleanup.ps1`

## Safety Design

- Uses a dry run mode to show which files would be removed.
- Only targets files older than the configured number of days.
- Skips locked files and logs the failure without stopping the run.
- Handles errors per file so one problem file does not stop the whole script.
- Writes a timestamped log file for every run.
- Writes a manifest for each cleanup run so files can be restored later.
- Only writes a rollback manifest when at least one file was moved.
- Is idempotent because already-moved files are no longer in the source path, and restored items are tracked in the manifest.

## Default Behavior

If you run the script without parameters, it:

- Scans the current temp path returned by `[System.IO.Path]::GetTempPath()`.
- Scans `C:\Windows\Temp`.
- Includes files older than `0` days.
- Moves eligible files into `Day3\TempCleanup-Quarantine`.
- Writes log files into `Day3\Logs`.

## Parameters

### Cleanup mode

- `-Paths <string[]>`
  One or more folders to scan recursively.

- `-OlderThanDays <int>`
  Minimum file age in days. Default is `0`.

- `-DryRun`
  Shows the files that would be removed and writes them to the log, but does not move anything.

- `-QuarantineRoot <string>`
  Folder used to store quarantined files and manifests.

- `-LogRoot <string>`
  Folder used to store timestamped log files.

### Rollback mode

- `-Rollback`
  Restores files from the latest cleanup manifest unless another manifest is specified.

- `-OperationId <string>`
  Restores files from a specific cleanup run. The operation ID matches the unique run ID used in the manifest name.

- `-RollbackManifestPath <string>`
  Restores files using a specific manifest file.

## Examples

Dry run with defaults:

```powershell
.\Day3\temp-file-cleanup.ps1 -DryRun
```

Remove files older than 7 days from default temp locations:

```powershell
.\Day3\temp-file-cleanup.ps1 -OlderThanDays 7
```

Scan a custom path only:

```powershell
.\Day3\temp-file-cleanup.ps1 -Paths 'C:\Temp','C:\Users\Public\AppData\Local\Temp' -OlderThanDays 3
```

Rollback the latest cleanup run:

```powershell
.\Day3\temp-file-cleanup.ps1 -Rollback
```

Rollback a specific cleanup run:

```powershell
.\Day3\temp-file-cleanup.ps1 -Rollback -OperationId 20260805-101500-123-4567
```

Rollback from a specific manifest file:

```powershell
.\Day3\temp-file-cleanup.ps1 -Rollback -RollbackManifestPath '.\Day3\TempCleanup-Quarantine\Manifests\cleanup-manifest-20260805-101500-123-4567.json'
```

## Operational Notes

- Dry run prints `DRY RUN: would delete ...` for each candidate file.
- Cleanup mode moves files into quarantine rather than permanently deleting them.
- If a cleanup run moves no files, the script logs that result and does not create a rollback manifest.
- Rollback does not overwrite files that already exist in the original location; it logs and skips them.
- Run elevated if the target temp folders require administrator access.