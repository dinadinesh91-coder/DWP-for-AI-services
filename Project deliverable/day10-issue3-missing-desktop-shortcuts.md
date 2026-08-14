# Day 10 Issue 3: Missing Desktop Shortcuts (Floor 6)

Date: 2026-08-14  
Analyst: DWP Engineer  
Evidence boundary: Scope facts only from initial Slack report.

## Scope Facts Used
- At least one report that desktop shortcuts vanished
- Same floor also experiencing slow/can't-login symptoms
- Friday app deployment to Floor 6 and Win11 migration completed last Friday (with Intune enrollment)

## Immediate Triage Focus
What to check first:
1. Determine if this is shortcut/path presentation drift vs actual file loss.
2. Compare Desktop and Public Desktop paths on affected vs unaffected devices.
3. Check whether shortcut issue is coupled with slow-login users.

Why first:
- Quickly separates lower-risk UI/path drift from true data-loss concerns.

## Ranked Differential (Most Probable First, No Final Commitment)

### 1) Profile/shell path redirection issue after migration
Why it fits:
- Recent Win11 migration can shift shell folder paths or profile resolution.
- Commonly presents as "shortcuts vanished" when they moved location.

Fastest check:
- Verify current user Desktop path and shell folder registry keys on affected device.

### 2) OneDrive Known Folder Move convergence delay/conflict
Why it fits:
- KFM timing issues can make Desktop appear empty temporarily.

Fastest check:
- Check OneDrive sync/KFM status and whether Desktop content exists in synced path.

### 3) Friday app install replaced/removed shortcuts
Why it fits:
- App deployments often modify desktop shortcuts; timing aligns with Friday rollout.

Fastest check:
- Compare shortcut inventory and app install actions on affected devices vs control device.

### 4) Temporary profile loaded due to login/profile service error
Why it fits:
- Temporary profiles show near-empty desktops and can coincide with login issues.

Fastest check:
- Check User Profile Service events indicating temporary profile load.

### 5) GPO/Intune policy conflict controlling desktop items
Why it fits:
- Recent management transition can cause policy overlap and unexpected desktop behavior.

Fastest check:
- Review resultant policy settings affecting Desktop visibility and shell behavior.

### 6) Windows 11 migration left stale user profile mapping (old SID/profile path reference)
Why it fits:
- Post-migration profile remapping can leave broken desktop references even when files still exist.
- Common in first login cycles after device join/profile transition.

Fastest check:
- Check `ProfileList` SID-to-path mapping in registry and confirm the signed-in SID maps to the active user profile path.

## Current Position
- Most likely non-destructive path/policy issue, but verify before reassurance.
- Handle alongside login investigation because both may share profile root cause.
