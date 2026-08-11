# Day 5 RCA: Finance Shared Drive Access Failure on Win11

Date written: 2026-08-07  
Incident context date: 2024-03-14 to 2024-03-15  
Prepared by: DWP Engineering

## 1. Executive Summary
Finance users were unable to access mapped shared drives after a drive-mapping delivery change. The drive mapping script was migrated from a user-context GPO logon script to an Intune PowerShell script executing in SYSTEM context, and the script behavior was not adjusted for that context. This caused mapping failures, including Network name cannot be found errors and missing S: drive assignment.

Resolution was applied by moving the mapping approach back to a user-context-compatible execution model and validating mapping behavior after deployment. Issue is resolved, user login to host was verified, and no further issues were reported.

## 2. Scope and Impact
- Affected population: Finance users on DESKTOP-FB devices in OU=Finance (reported user impact across 45 users).
- Technical symptom: Finance mapped drive path could not be mapped during the incident window.
- Business impact: Finance users could not access required shared-drive content until remediation was applied.

## 3. Supporting Evidence
### A. Intune Management Extension evidence
- 08:00:01 ScriptRunner Info: Executing Map-FinBridgeDrives.ps1.
- 08:00:02 ScriptRunner Info: Script context is SYSTEM account.
- 08:00:03 ScriptRunner Warning: Network path \\finbridge-fs01\Finance not accessible from SYSTEM context at execution time.
- 08:00:03 ScriptRunner Error: Script failed, exit code 1, Network name cannot be found.
- 08:00:04 ScriptRunner Info: No retry configured.

### B. System log evidence from DESKTOP-FB041
- 08:00:05 Service Control Manager Event 7036: Workstation service entered running state.
- 08:00:06 GroupPolicy Event 1500: Group Policy settings processed successfully.
- 08:00:07 Ntfs Event 98 Warning: Could not map drive letter S: drive letter not assigned.

### C. Change record evidence
- 2024-03-14 23:30 migration note: mapping changed from GPO logon script running as USER to Intune PowerShell script running as SYSTEM, and script was not updated for SYSTEM-context behavior.

## 4. Incident Timeline
1. 2024-03-14 23:30: Drive mapping delivery changed from USER-context GPO logon script to SYSTEM-context Intune script.
2. 08:00:01: Intune ScriptRunner starts Map-FinBridgeDrives.ps1.
3. 08:00:02: ScriptRunner confirms SYSTEM context.
4. 08:00:03: UNC path access warning and script failure with Network name cannot be found.
5. 08:00:04: ScriptRunner records no retry configured.
6. 08:00:05: Workstation service is running.
7. 08:00:06: Group Policy reports successful processing.
8. 08:00:07: Ntfs Event 98 indicates S: mapping not assigned.
9. Post-triage and remediation: mapping execution model corrected to user-context-compatible approach and rollout validated.
10. Post-fix validation: issue resolved; user login verified on host and no further issue reported.

## 5. 5 Whys Analysis
1. Why could Finance users not access shared drives?
Because the mapped drive was not being created successfully.

2. Why was the mapped drive not being created?
Because the mapping script failed with Network name cannot be found and ended with exit code 1.

3. Why did the mapping script fail?
Because it executed in SYSTEM context where the implemented mapping behavior for user drive mapping did not work as designed.

4. Why was it executing in SYSTEM context?
Because the delivery method was migrated from GPO user logon script to Intune PowerShell script configured to run as SYSTEM.

5. Why did this migration introduce failure?
Because the script and deployment controls were not updated to validate execution-context compatibility before rollout, and no retry behavior was configured.

## 6. Root Cause Statement
Primary root cause: execution-context mismatch introduced by migration of drive mapping from USER-context GPO script to SYSTEM-context Intune script without script adaptation for that context.  
Immediate technical effect: mapping attempt to \\finbridge-fs01\Finance failed in script runtime, resulting in no S: drive assignment.

## 7. Resolution Implemented
1. Replaced or adjusted mapping deployment to a user-context-compatible execution model for Finance drive mapping.
2. Reapplied mapping configuration to affected scope.
3. Validated that mapped drive assignment succeeds after sign-in in user session.
4. Confirmed restoration with user verification on host.

## 8. Verification of Recovery
- User confirmation: user logged in successfully and reported no issues.
- Technical confirmation: prior failure signals were addressed, including script context mismatch and missing mapped drive behavior.
- Operational outcome: service restored for affected workflow.

## 9. Preventive and Corrective Actions
### Immediate controls
1. Require execution-context review for any migration from GPO logon script to Intune script.
2. Require explicit validation of mapped drive behavior in signed-in user context before production rollout.
3. Add retry or remediation behavior for mapping failures instead of single-attempt failure.

### Engineering hardening
1. Add deployment gate in change checklist: user-vs-system execution compatibility approved.
2. Add pilot ring validation on representative Finance endpoints before broad assignment.
3. Add known-error triage checklist for ScriptRunner Network name cannot be found plus Ntfs Event 98 mapping failures.

### Governance
1. Update migration template to include context-compatibility test evidence.
2. Require peer review for endpoint script context changes that affect user resource access.
3. Record closure evidence in post-implementation review.

## 10. Lessons Learned
- Successful Group Policy processing does not validate mapped-drive deployment path when mapping mechanism is external to GP.
- Script execution context is a critical dependency for user resource mapping.
- Context-aware pilot validation should be mandatory for endpoint migration changes.

## 11. Closure Status
Closed: remediation applied and verified.  
User validation: login to host confirmed and no issues reported.
