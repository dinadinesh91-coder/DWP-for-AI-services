# Floor 6 File Cleanup Script README

Script: floor6-file-cleanup-with-rollback.ps1

## Purpose
This script performs controlled file cleanup with the following capabilities:
- Dry run listing of files that would be removed
- Age-based targeting using a configurable days threshold
- Locked-file skip with warning logs
- Per-file try/catch handling so one error does not stop the run
- Timestamped action logging
- End-of-run summary report
- Rollback support using a generated manifest
- Idempotent behavior through safe skips and deterministic staging

## Parameters
- TargetPath (required): Root folder to scan
- OlderThanDays (optional, default 0): Only files older than this many days are eligible
- DryRun (optional): Lists candidate files and logs actions without moving files
- Rollback (optional): Restores files from a previous manifest instead of cleanup
- ManifestPath (required for Rollback): JSON manifest path from a prior cleanup run
- LogDirectory (optional): Where logs and manifests are written
- QuarantineRoot (optional): Where files are staged during cleanup

## How Cleanup Works
1. Enumerates files under TargetPath recursively.
2. Filters files older than OlderThanDays.
3. In DryRun mode, prints each candidate file.
4. In execute mode:
- Skips locked files
- Moves eligible files to a run-specific quarantine folder
- Writes manifest for rollback

## How Rollback Works
1. Reads a prior manifest JSON.
2. Restores each staged file to original location.
3. Skips restore when destination already exists.
4. Logs all actions and emits a summary.

## Examples
Dry run:
```powershell
.\floor6-file-cleanup-with-rollback.ps1 -TargetPath "C:\Temp\CleanupTarget" -OlderThanDays 30 -DryRun
```

Execute cleanup:
```powershell
.\floor6-file-cleanup-with-rollback.ps1 -TargetPath "C:\Temp\CleanupTarget" -OlderThanDays 30
```

Rollback:
```powershell
.\floor6-file-cleanup-with-rollback.ps1 -TargetPath "C:\Temp\CleanupTarget" -Rollback -ManifestPath "C:\Path\To\manifest-20260814-103000.json"
```

## Notes
- Cleanup uses move-to-quarantine rather than hard delete to enable rollback.
- Locked files are skipped and logged, not treated as fatal.
- For idempotency, repeated rollback skips files that are already restored or missing in staging.
