# L2 Technical Article: Floor 6 Login Fix

Version: v3.0  
Date: 2026-08-14  
Audience: L2/L3 engineers  
Related runbook: floor6-issue1-runbook-login-fix-v3.md

## Overview
This article provides the technical context and validation approach for the Floor 6 sign-in issue. Follow the associated runbook for step-by-step remediation procedures.

## Root Cause
Friday app deployment of "FinBridge Document Management" to Floor 6 (Legal team, 45 users) is causing extended sign-in delays and sign-in failures on Monday morning. The application's startup initialization, installation retry logic, or performance requirements are blocking the Windows sign-in shell process.

## Scope
- **Affected population**: Floor 6 Legal team (approximately 45 users)
- **Affected devices**: All devices in Floor 6 device group with FinBridge app assignment
- **Impact window**: Monday 2026-08-14 morning (first sign-in after Friday deployment)
- **Symptom**: Sign-in delays (5–15 minutes or longer) or complete sign-in failure
- **Mitigation**: Remove app from assignment; allow uninstall to propagate

## Differential Diagnosis
The following ranked hypotheses guided triage:

1. **Friday app deployment regression** (highest confidence)
   - Exact timing match: Friday rollout → Monday morning failures
   - Exact population match: Floor 6 assignment → Floor 6 affected
   - Symptom fit: App startup delays extend sign-in process
   
2. Intune assignment or detection-rule retry loop  
3. Win11 profile migration side effects  
4. Identity token/session state drift after migration  
5. Monday morning shared-service contention

## Remediation Overview

### Phase 1: Evidence Collection (Pre-Change)
Before applying any change, capture baseline diagnostics from one affected device:
```powershell
.\floor6-login-check-corrected.ps1 -AppDisplayName "FinBridge Document Management" -LookbackHours 72 -OutputPath "C:\Temp\Floor6-Pre.json"
```
This generates structured JSON with application install status, profile load events, and performance metrics for comparison.

### Phase 2: Remediation
Submit an **uninstall assignment** for the FinBridge app to the Floor 6 device group via Microsoft Graph API (see runbook for full command).

**Key details**:
- Assignment intent: `uninstall`
- Target group: Floor 6 device group
- Graph scopes required: `DeviceManagementApps.ReadWrite.All`, `Group.Read.All`, `DeviceManagementManagedDevices.PrivilegedOperations.All`

### Phase 3: Pilot Validation
Force synchronization on 3 sample impacted devices and monitor for recovery:
- Check Intune console: uninstall status changes to "Success"
- Monitor service desk: sign-in failure tickets decline in pilot devices
- Confirm with users: sign-in performance returns to normal

### Phase 4: Evidence Collection (Post-Change)
After pilot devices recover, capture post-change diagnostics:
```powershell
.\floor6-login-check-corrected.ps1 -AppDisplayName "FinBridge Document Management" -LookbackHours 24 -OutputPath "C:\Temp\Floor6-Post.json"
```

## Verification Criteria
✓ Intune assignment status shows `uninstall` intent applied to Floor 6 group  
✓ Pilot devices complete uninstall successfully within 2 hours  
✓ Sign-in duration normalizes (baseline <2 min vs. incident baseline 5–15+ min)  
✓ No sustained IME/shell delay patterns in post-change evidence  
✓ Service desk sign-in incident volume drops within next business cycle  
✓ Affected users report normal sign-in  

## Rollback Procedure
If the uninstall introduces unexpected issues:

1. Remove the uninstall assignment from Floor 6 device group.
2. Do **not** immediately reassign the original app.
3. Instead, create a small pilot ring (2–3 devices) and deploy only to that ring.
4. Monitor for full business day.
5. Only expand if no regression is observed.
6. Document any blockers before re-rollout.

## Notes
- This incident is isolated to Floor 6 and does not affect other floors.
- Desktop shortcuts issue (Issue 3) and Copilot security concern (Issue 2) are separate; handle on independent tracks.
- Confirm app ID and device group ID before submitting Graph API requests.
- Keep runbook procedures available for escalation to L3 if pilot validation shows unexpected behavior.
4. Incident volume declines in service desk queue.

## Rollback-of-Rollback
If business requires app restoration:
1. Remove uninstall assignment.
2. Re-deploy to limited pilot ring only.
3. Observe one full business day before broad rollout.
