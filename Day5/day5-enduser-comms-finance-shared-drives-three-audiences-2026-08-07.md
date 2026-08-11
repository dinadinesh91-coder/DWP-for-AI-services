# Day 5 Communications Pack: Finance Shared Drives Incident

## Audience 1 - Non-technical executive
Your access is restored and your data is safe. Finance users could not open shared drives after a setup change moved drive setup from user sign-in to device startup, and that change was not adjusted for the new method, so the Finance drive was not created. We corrected the setup and verified access is working. You do not need to do anything unless the issue returns; if it does, contact the Service Desk.

## Audience 2 - Affected end-user team (10 people, non-technical)
Your access is restored and your data is safe. Finance shared drives stopped opening because drive setup was moved from the normal sign-in method to a device startup method that was not updated for that change, so the Finance drive did not get created. We corrected the setup and confirmed access works again. If you see the same issue, contact the Service Desk and mention the Finance shared drive incident. Contact: Service Desk.

## Audience 3 - Engineer-to-engineer internal note
Status: Resolved. User login to host verified and no further issues reported.

Root cause:
- Drive mapping delivery was migrated 2024-03-14 23:30 from USER-context GPO logon script to Intune PowerShell execution in SYSTEM context.
- Mapping logic was not adapted for SYSTEM runtime, causing access failure to \\finbridge-fs01\Finance at execution time and no S: assignment.

Supporting evidence:
- IME log:
  - 08:00:01 ScriptRunner Info: Executing Map-FinBridgeDrives.ps1.
  - 08:00:02 ScriptRunner Info: Script context SYSTEM.
  - 08:00:03 ScriptRunner Warning/Error: \\finbridge-fs01\Finance not accessible; exit code 1; Network name cannot be found.
  - 08:00:04 ScriptRunner Info: No retry configured.
- System log (DESKTOP-FB041):
  - 08:00:05 SCM 7036: Workstation service running.
  - 08:00:06 GroupPolicy 1500: GP processed successfully.
  - 08:00:07 Ntfs 98: S: not assigned.

Exact action taken:
1. Replaced/adjusted mapping deployment to a user-context-compatible execution model.
2. Reapplied mapping configuration to affected Finance scope.
3. Validated mapped drive creation and access in user session post sign-in.

Config detail:
- Previous state: GPO logon script in USER context.
- Changed state that caused issue: Intune script in SYSTEM context.
- Corrected state: user-context-compatible mapping execution for Finance drive mapping.

Verification steps:
1. Confirm no recurrence of IME mapping failure sequence (Network name cannot be found, exit code 1).
2. Confirm absence of Ntfs Event 98 for missing S: mapping.
3. Confirm user can log in and access Finance share successfully.

Preventive action needed:
1. Enforce execution-context review gate for any GPO-to-Intune script migration.
2. Require UAT in signed-in user session for mapped-drive scenarios before broad rollout.
3. Add retry/remediation behavior for mapping task and pilot ring validation before full deployment.
