# Day 5 Analysis and Hypothesis

Date: 2026-08-07  
Analyst: DWP Engineer  
Scope: Three Windows 11 machines; Finance team cannot access shared drives (45 users).

## Constraint
This ranking is based only on the provided scope fact. No single root cause is being declared at this stage.

## Ranked Top 5 Likely Causes (Most probable first)

### 1) File server share/NTFS permission or AD group membership change affecting Finance access
Why this fits the scope facts:
- The symptom is access failure to shared drives for a whole business function (Finance, 45 users), which strongly aligns with entitlement or group-based authorization breakage.
- A permission/group change can affect many users at once while still being noticed first from a subset of endpoints.

Single fastest check:
- From one affected user account, verify effective access on the target share path and confirm Finance AD group membership is present and unchanged.

### 2) DFS Namespace or mapped drive target path changed/unavailable for Finance share
Why this fits the scope facts:
- Shared drive failures at team scale often occur when DFS referrals or target paths move, go offline, or are renamed.
- Users can all lose access simultaneously if a common logical path breaks.

Single fastest check:
- On one affected machine, run `dfsutil /pktinfo` and test direct UNC access to the backend target server to confirm whether namespace referral or target availability is failing.

### 3) Domain authentication/token issue (Kerberos ticketing or stale logon token) blocking SMB authorization
Why this fits the scope facts:
- Shared drive access relies on domain-authenticated SMB authorization; if tickets/tokens are invalid, users can authenticate to Windows but fail resource access.
- Multi-user impact can appear when ticketing or identity context is disrupted for a department.

Single fastest check:
- On an affected endpoint, run `klist` and attempt the share with fresh credentials after `klist purge` + sign-out/sign-in to see if access behavior changes.

### 4) Network path/firewall/routing issue between affected clients and file server(s)
Why this fits the scope facts:
- If file server network paths are blocked or unstable, shared drives will fail regardless of user permissions.
- Partial endpoint count in scope (three Win11 machines) can still be an early sample of a wider network segment issue impacting Finance users.

Single fastest check:
- From one affected machine, test SMB reachability with `Test-NetConnection <fileserver> -Port 445` and confirm UNC path access.

### 5) Drive mapping policy/script failure for Finance users on Win11
Why this fits the scope facts:
- Team-level drive access can fail if the mapping mechanism (GPO Preferences/logon script) stopped applying.
- This can produce "cannot access shared drives" reports even if backend shares are healthy.

Single fastest check:
- On one affected machine, run `gpresult /r` (or Resultant Set of Policy) to confirm drive-mapping policy/script applied status, then test manual UNC access to distinguish mapping failure from share failure.

## Working Hypothesis
The highest-likelihood cluster is access entitlement/path dependency (permissions/group membership or DFS/share target availability), with authentication and network path issues as secondary candidates. Policy mapping failure remains plausible but lower until manual UNC and backend access checks are performed.

## Immediate Triage Order (Fastest elimination path)
1. Validate effective permissions and Finance group membership for one affected user.
2. Test direct UNC path and DFS referral/target state.
3. Check Kerberos ticket/token state and retry access.
4. Validate SMB network reachability to file server (port 445).
5. Confirm drive mapping policy/script application status.

## Evidence Assessment Against Each Hypothesis (Incident Window)

Source reviewed:
- Intune Management Extension script execution records (08:00:01-08:00:04)
- System Log, DESKTOP-FB041 (08:00:05-08:00:07)
- Migration change note (2024-03-14 23:30)

### 1) File server share/NTFS permission or AD group membership change affecting Finance access
Judgement: Neutral

Why:
- The provided evidence shows mapping execution failure and network-name resolution in script context, but it does not show explicit access denied or ACL rejection for user identity.

Determining evidence:
- 08:00:03, ScriptRunner Error: `Map-FinBridgeDrives.ps1` failed with "Network name cannot be found" (no NTFS/authorization denial message captured).
- 08:00:07, Ntfs Event 98 (Warning): drive letter S: could not be mapped; this confirms mapping failure but not permission denial.

### 2) DFS Namespace or mapped drive target path changed/unavailable for Finance share
Judgement: Supports (partial)

Why:
- The error "Network name cannot be found" is consistent with an unavailable or unresolved share path at execution time.
- Evidence does not explicitly prove DFS referral failure, so support is limited to path-unavailable behavior.

Determining evidence:
- 08:00:03, ScriptRunner Error: "Network name cannot be found" for `\\finbridge-fs01\\Finance`.
- 08:00:07, Ntfs Event 98 (Warning): S: mapping not assigned.

### 3) Domain authentication/token issue (Kerberos ticketing or stale logon token) blocking SMB authorization
Judgement: Contradicts

Why:
- Logs indicate policy processing success and mapping failure tied to script execution context, not a user-token authorization breakdown.

Determining evidence:
- 08:00:06, GroupPolicy Event 1500: Group Policy processed successfully.
- 08:00:03, ScriptRunner Info/Warning/Error sequence: script executed in SYSTEM context and failed on UNC path accessibility.

### 4) Network path/firewall/routing issue between affected clients and file server(s)
Judgement: Neutral

Why:
- "Network name cannot be found" can align with connectivity/path problems, but the migration note also provides a direct script-context explanation.
- Current evidence does not isolate routing/firewall as the sole mechanism.

Determining evidence:
- 08:00:03, ScriptRunner Error: network name cannot be found.
- 08:00:05, Service Control Manager Event 7036: Workstation service running, so basic SMB client service state is up; does not independently prove network block.

### 5) Drive mapping policy/script failure for Finance users on Win11
Judgement: Supports

Why:
- Evidence directly records script execution failure for the drive mapping script in SYSTEM context, plus a no-retry behavior.
- Change log explicitly states migration from USER-context GPO script to SYSTEM-context Intune script without required handling changes.

Determining evidence:
- 08:00:01, ScriptRunner Info: executing `Map-FinBridgeDrives.ps1`.
- 08:00:02, ScriptRunner Info: script context is SYSTEM account.
- 08:00:03, ScriptRunner Warning/Error: UNC path not accessible in SYSTEM context; exit code 1; "Network name cannot be found".
- 08:00:04, ScriptRunner Info: no retry configured.
- 08:00:07, Ntfs Event 98 (Warning): S: drive letter not assigned.
- 2024-03-14 23:30, migration change note: mapping mechanism changed to Intune SYSTEM context and script was not updated for SYSTEM execution constraints.

## Status
All five hypotheses have been evaluated against current evidence, and no final winner is selected in this section.

## Addendum: Event Details, Surviving Hypothesis, and Resolution

### Event Detail Summary (Incident Window)
- 08:00:01, ScriptRunner Info: executing `Map-FinBridgeDrives.ps1`.
- 08:00:02, ScriptRunner Info: script executed in SYSTEM context.
- 08:00:03, ScriptRunner Warning: `\\finbridge-fs01\\Finance` not accessible from SYSTEM context at execution time.
- 08:00:03, ScriptRunner Error: script failed with exit code 1, "Network name cannot be found".
- 08:00:04, ScriptRunner Info: no retry configured.
- 08:00:05, Service Control Manager Event 7036: Workstation service entered running state.
- 08:00:06, GroupPolicy Event 1500: Group Policy settings processed successfully.
- 08:00:07, Ntfs Event 98 (Warning): drive letter S: not assigned.
- Prior change note, 2024-03-14 23:30: drive mapping migrated from GPO USER-context logon script to Intune PowerShell script running as SYSTEM; script not updated for SYSTEM-context behavior.

### Surviving Hypothesis
Hypothesis 5 survives elimination:
- Drive mapping policy/script failure caused by execution-context mismatch (script moved from USER context to SYSTEM context), resulting in mapping failure for Finance shared drives.

### Detailed Resolution Steps
1. Restore service path quickly
- Revert Finance drive mapping to a USER-context execution model (known-good GPO logon script behavior) or deploy an Intune user-context mapping method.

2. Correct mapping implementation
- Update `Map-FinBridgeDrives.ps1` to run in user context and avoid SYSTEM-dependent assumptions for user drive mappings.
- Keep explicit error handling for UNC resolution and mapping failures.

3. Fix deployment configuration
- In Intune assignment, configure delivery in user context for Finance users/devices.
- Add retry/remediation behavior so transient startup timing does not leave users unmapped for the session.

4. Validate technical recovery
- Confirm S: mapping is created in user session and points to the expected Finance path.
- Recheck logs for absence of the prior failure sequence:
	- ScriptRunner "Network name cannot be found"
	- Ntfs Event 98 for missing S: mapping

5. Complete controlled rollout
- Pilot on affected DESKTOP-FB cohort, then expand to all Finance assignments after successful verification.

6. Prevent recurrence
- Add a mandatory execution-context review gate for any migration from GPO logon script to Intune script.
- Add UAT checklist step requiring mapped drive validation in signed-in user context.
- Define rollback trigger if initial deployment wave shows recurring mapping failures.
