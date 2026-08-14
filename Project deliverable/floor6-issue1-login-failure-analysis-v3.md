# Floor 6 Issue 1: Login Failure and Sign-In Slowness (Scope-Facts Analysis)

Version: v3.0  
Date: 2026-08-14  
Author: DWP Engineer

## Scope Facts Used
- Floor 6 Legal, 45 users
- Recently migrated to Win11 and enrolled in Intune
- Monday morning: at least a dozen users cannot log in or sign-in is very slow
- Friday afternoon: new document-management app deployed to this exact floor

## First 30 Minutes Triage (This Issue)
1. Confirm blast radius by affected users/devices.
Why: Separates local endpoint failure from floor-wide service-impact.

2. Time-align first failures against Friday deployment and Monday start-of-day.
Why: Strongest early correlation test for a change-induced incident.

3. Compare assignment state: affected devices vs one unaffected control.
Why: Fastest path to determine whether rollout targeting is causal.

## Ranked Differential (Most Probable First, No Final Commitment)

### 1) Friday app deployment regression on Floor 6
Why this fits scope facts:
- Exact population match: rollout targeted this floor.
- Exact timing match: Friday rollout, Monday failure cluster.
- Symptom fit: startup extension, service init delay, or install retry loop can cause long/failed sign-in.

Single fastest check:
- On 3 affected devices, compare app install timestamp/version and IME app activity to first slowdown timestamp; compare with 1 unaffected control device.

Evidence confirms deployment as cause:
- Affected devices show app installed before symptom onset.
- IME shows retry/failure or prolonged processing tied to app package.
- Control device outside assignment lacks same pattern.

Evidence rules out deployment as cause:
- Same sign-in pattern appears on devices without app assignment/install.
- Symptom onset predates app install timestamp.

### 2) Intune assignment or detection rule loop
Why this fits scope facts:
- Recent Intune onboarding increases mis-scope/detection-edge risk.
- Retry loops can lock sign-in performance and appear as failures.

Single fastest check:
- Review Intune app install status for repeated failed/retried detection/install states in Floor 6 cohort.

### 3) Win11 profile migration side effects
Why this fits scope facts:
- Recent migration can cause profile load delays and shell resolution issues.
- Sign-in slowness and desktop symptom can share one profile root.

Single fastest check:
- Check User Profile Service events and profile path resolution on one affected endpoint.

### 4) Identity token/session state drift after migration
Why this fits scope facts:
- "Cannot log in" can map to stale or failed auth/session refresh.
- Can hit a subset of users after migration changes.

Single fastest check:
- Check Entra sign-in outcomes for sampled affected user/device pairs in incident window.

### 5) Monday morning shared-service contention
Why this fits scope facts:
- Monday peak can produce partial auth/logon latency bursts.
- May coexist with migration-related sensitivity.

Single fastest check:
- Compare sign-in latency and failure rates across other floors during same window.

## Working Position
No single cause is selected yet. Ranking is based on scope fit and fastest validation path only.
