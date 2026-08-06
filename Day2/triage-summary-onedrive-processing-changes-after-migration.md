# Structured Triage Summary

## Summary (one line)
OneDrive is stuck on processing changes after migration, and files are missing locally.

## Impact (who/how many/business urgency)
- Who: One end user relying on OneDrive local sync after migration (to-verify).
- How many: Single reported user/device so far (to-verify).
- Business urgency: Medium to high because local files appear missing and normal file access may be disrupted (to-verify).

## Known facts
- Ticket reference is T-1007.
- OneDrive shows processing changes.
- The issue started after a migration.
- Files are reported missing locally.

## Missing information to gather
- Whether files are missing only locally or also missing in OneDrive on the web.
- Whether the user can see the expected files online.
- Approximate number and type of missing files or folders.
- Whether the sync client is signed in correctly and shows any banner or sync error text.
- Whether the device has sufficient local disk space.
- Whether Files On-Demand or selective sync settings changed after migration (to-verify).
- Whether other migrated users are seeing the same behavior.

## Likely category
OneDrive sync / post-migration file availability issue.

## First diagnostic step
Confirm whether the missing files are present in OneDrive on the web; if they are online, focus first on local sync state and migration-related client configuration rather than assuming data loss.
