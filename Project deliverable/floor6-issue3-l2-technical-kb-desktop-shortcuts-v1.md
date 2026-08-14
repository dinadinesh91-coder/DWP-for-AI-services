# L2 Technical KB: Floor 6 Missing Desktop Shortcuts (Win11 Migration Context)

Version: v1.0  
Date: 2026-08-14  
Audience: L2/L3 engineers  
Related runbook: floor6-issue3-runbook-desktop-shortcuts-v1.md

## Incident Trigger Conditions

Use this article when:
- Users on Floor 6 report missing desktop shortcuts or files after Win11 migration and Friday app rollout
- User states desktop appears empty or contains fewer items than expected
- Issue occurs during same Monday incident window as login slowness and Copilot concerns

## Root Cause Context

This issue is **almost always a visibility/path problem, not data loss**. The most likely causes are:

1. **Shell folder path drift** – Windows registry path for "Desktop" points to wrong location
2. **Win11 migration artifacts** – Profile path remapping incomplete or stale
3. **OneDrive KFM convergence delay** – Known-Folder-Move sync incomplete
4. **App rollout side effects** – Friday deployment modified shortcut baseline
5. **Temporary profile loaded** – User session using temporary profile after sign-in issue

## Pre-Triage Assessment

Before escalating to L3 or data-loss response:

| Finding | Interpretation | Next Action |
|---|---|---|
| Files visible in `%USERPROFILE%\Desktop` | Desktop path is correct; visibility lag only | User sign-out/sign-in cycle or clear browser cache |
| Files visible in `C:\Users\Public\Desktop` | Files exist but user path incorrect | Correct user Desktop registry path |
| Files exist in OneDrive managed folder | KFM sync active; files in cloud location | Wait for OneDrive sync or trigger manual sync |
| No files anywhere | Potential data loss | Escalate to L3 and data recovery procedures |

## Detailed Triage Procedure

Follow steps from the runbook in sequence. This section summarizes the key checks:

### 1. Current User and SID Verification
```powershell
whoami
whoami /user
```
Expected: Active user SID displayed (e.g., `S-1-5-21-...`)

### 2. Read Active Desktop Shell Path
```powershell
Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name Desktop
```
Expected: Path value pointing to `%USERPROFILE%\Desktop` or `C:\Users\<username>\Desktop`

### 3. List Files in User Desktop Path
```powershell
Get-ChildItem -Path ([Environment]::GetFolderPath('Desktop')) -Force -ErrorAction SilentlyContinue | Select-Object -First 20 FullName
```
Expected: List of shortcuts/files (or empty result if truly missing)

### 4. List Files in Public Desktop
```powershell
Get-ChildItem -Path "C:\Users\Public\Desktop" -Force -ErrorAction SilentlyContinue | Select-Object -First 20 FullName
```
Expected: Shared desktop shortcuts visible (if any exist)

### 5. Validate SID-to-Profile Mapping (Admin Required)
```powershell
Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" | ForEach-Object {
  $p = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue
  [pscustomobject]@{ SID = $_.PSChildName; ProfileImagePath = $p.ProfileImagePath }
}
```
Expected: Signed-in user's SID maps to active profile path like `C:\Users\<username>`

### 6. Check OneDrive Sync State
```powershell
Get-Process OneDrive -ErrorAction SilentlyContinue | Select-Object Name, Id, StartTime
```
Expected: OneDrive running (may indicate KFM is active or pending)

## Corrective Actions (In Priority Order)

### Action 1: Incorrect Desktop Path in Registry
If Step 2 shows Desktop path pointing to wrong location (e.g., `C:\OldPath\Desktop`):

**Backup first (mandatory)**:
```powershell
reg export "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" "C:\Temp\Issue3-UserShellFolders-Backup.reg" /y
```

**Correct the path**:
```powershell
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name Desktop -Value "%USERPROFILE%\Desktop"
```

**Force policy refresh and sign-out/sign-in**:
```powershell
gpupdate /force
shutdown /l
```

**User action**: Sign in again; desktop should show correct files.

### Action 2: Stale SID-to-Profile Mapping
If Step 5 shows SID mapping to old/incorrect path:

⚠️ **Do not edit `ProfileList` registry directly without L3 approval.** This can break user profile loading.

Escalate to L3 endpoint engineering with:
- Steps 2, 3, 5, 6 output
- Device name and username
- Incident ticket number

### Action 3: OneDrive KFM Delay
If OneDrive is running but files only exist in OneDrive cloud path:

- Wait 5–10 minutes for KFM sync to complete
- If still delayed, trigger manual refresh: Right-click OneDrive tray icon → Help & Settings → Sync now
- Re-check after 5 minutes

### Action 4: App Rollout Modified Shortcuts
If no files exist anywhere but user suspects app rollout changed shortcuts:

- Check Intune app assignment for changes on that device
- Determine if shortcuts were part of the Friday deployment
- Consider app rollback (see Issue 1 runbook) if FinBridge app modified baseline

### Action 5: Temporary Profile Active
If SID mapping shows temporary profile path (e.g., `C:\Users\TEMP.S-1-5-21-...-...`):

- User is on temporary profile (likely due to sign-in issue affecting profile load)
- Perform graceful sign-out/sign-in cycle
- If temporary profile persists, escalate to L3 with profile service events

## Verification Checklist

Before considering ticket resolved:

- ✓ Desktop registry path confirms baseline value: `%USERPROFILE%\Desktop`
- ✓ User's Desktop folder is accessible and contains expected shortcuts
- ✓ SID-to-profile mapping shows active (not temporary) profile path
- ✓ User signs out and signs in; desktop persists correctly
- ✓ No new related incidents within next 24 hours
- ✓ User confirms desktop shortcuts/files are visible

## Edge Cases and Warnings

| Edge Case | Handling |
|---|---|
| User on temporary profile | Do not make permanent changes; fix profile load first |
| OneDrive not running | Start OneDrive service; KFM may not be active |
| File exists only in `C:\Users\Public\Desktop` | Files are shared; user must add them to personal desktop |
| True file deletion confirmed | Do not attempt restore at L2; escalate to data-recovery procedures |
| Multiple users affected identically | Not profile-specific; check Intune policy or app rollout impact |

## Related Incidents (Do Not Merge)

- **Issue 1 (Login slowness)**: May be related if caused by same app deployment; handle on separate track
- **Issue 2 (Copilot security)**: Completely separate security concern; do not merge incident streams

## Rollback Procedure

If corrective action introduces unexpected behavior:

1. Import backup registry file:
```powershell
reg import "C:\Temp\Issue3-UserShellFolders-Backup.reg"
```

2. Sign out user:
```powershell
shutdown /l
```

3. Sign in and verify desktop returns to pre-change state.

4. Escalate to L3 with all evidence from triage steps and rollback confirmation.
