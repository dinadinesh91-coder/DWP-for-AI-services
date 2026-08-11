Symptom : Finance users cannot access the mapped shared drive, and drive letter S: is not assigned. Users report shared-drive access failure after sign-in.

Cause : The verified root cause is an execution-context mismatch introduced during migration from a USER-context GPO logon script to a SYSTEM-context Intune PowerShell script. The mapping script was not adapted for SYSTEM runtime, and the mapping to \\finbridge-fs01\Finance failed.

Scope : Affected users were Finance users on DESKTOP-FB devices in OU=Finance, with reported impact across 45 users. Evidence includes DESKTOP-FB041 system and Intune script logs.

Workaround : Restore service by using a user-context-compatible mapping method for the Finance drive instead of SYSTEM-context execution. Reapply mapping for the affected Finance scope and validate in a signed-in user session.

Permanent fix: Keep Finance drive mapping on a user-context-compatible execution model for this workflow and retire the failing SYSTEM-context mapping behavior. Enforce execution-context review and user-session validation as required controls before broad rollout.

How to spot it: Identify the pattern of Intune ScriptRunner entries showing Map-FinBridgeDrives.ps1 in SYSTEM context, followed by Network name cannot be found and exit code 1 (08:00:01-08:00:04). Correlate with System log signals: GroupPolicy Event 1500 success at 08:00:06, Ntfs Event 98 warning at 08:00:07 for missing S:, and module names ScriptRunner, GroupPolicy, Ntfs.
