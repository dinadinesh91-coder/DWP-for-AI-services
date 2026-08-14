# Floor 6 Issue 3: Desktop Files Reported Missing (Scope-Facts Analysis)

Version: v3.0  
Date: 2026-08-14  
Author: DWP Engineer

## Scope Facts Used
- User report: desktop shortcuts/files vanished.
- Same floor also experiencing login slowness/failures.
- Recent Win11 migration, Intune onboarding, and Friday app deployment.

## First 30 Minutes Triage (This Issue)
1. Determine if this is true file loss or visibility/path drift.
Why: Response differs sharply between data-loss and profile-path symptoms.

2. Check current Desktop path and Public Desktop path on affected endpoint.
Why: Fastest way to detect shell-folder path drift or profile mismatch.

3. Check OneDrive KFM/sync state and alternate expected desktop location.
Why: KFM convergence issues can make desktop appear empty while files still exist.

4. Compare affected endpoint with one unaffected control endpoint.
Why: Distinguishes user-specific profile state from broad policy behavior.

## Ranked Likely Causes (Most Probable First, No Final Commitment)
1. Profile/path visibility drift after migration.
2. OneDrive KFM or sync-state mismatch.
3. App deployment changed shortcuts only.
4. Temporary profile loaded after sign-in issue.
5. Policy conflict (Intune vs legacy settings) affecting shell folders.

## Single Fastest Check
Validate Desktop and Public Desktop path values plus file presence at both paths on one affected endpoint, then compare to one unaffected endpoint.

## Working Position
Most probable early pattern is visibility/path drift rather than true deletion, but this is not final until path/file-presence checks are complete.
