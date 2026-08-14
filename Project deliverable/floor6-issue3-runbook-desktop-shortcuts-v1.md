# Runbook: Issue 3 Missing Desktop Shortcuts (Floor 6)

Version: v1.0  
Date: 2026-08-14  
Owner: DWP Service Desk

## 1) Prerequisites
1. Access right: Local administrator rights on the affected endpoint.  
2. Access right: Intune admin center read access for policy and device status review.  
3. Access right: Service Desk permission to request/record user sign-out and restart windows.  
4. Tools: PowerShell 5.1+ and Registry Editor available on the endpoint.  
5. Systems: Access to affected endpoint and one unaffected control endpoint in same floor.  
6. Inputs: Affected username, endpoint hostname, and incident timestamp.

## 2) Procedure

Step 1 (elevated permission required): Open an elevated PowerShell session on the affected endpoint.  
Expected result: PowerShell runs as Administrator without UAC error.

Step 2: Record current user identity and SID.  
Action:
```powershell
whoami
whoami /user
```
Expected result: Username and SID are displayed for the active signed-in user.

Step 3: Read the active Desktop shell path for the signed-in user.  
Action:
```powershell
Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name Desktop
```
Expected result: Desktop path value is returned.

Step 4: Check file presence in resolved user Desktop path.  
Action:
```powershell
Get-ChildItem -Path ([Environment]::GetFolderPath('Desktop')) -Force -ErrorAction SilentlyContinue | Select-Object -First 20 FullName
```
Expected result: File list is returned or empty result is confirmed.

Step 5: Check file presence in Public Desktop path.  
Action:
```powershell
Get-ChildItem -Path "C:\Users\Public\Desktop" -Force -ErrorAction SilentlyContinue | Select-Object -First 20 FullName
```
Expected result: Public Desktop file list is returned.

Step 6 (elevated permission required): Read SID-to-profile mapping from ProfileList.  
Action:
```powershell
Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" | ForEach-Object {
  $p = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue
  [pscustomobject]@{ SID = $_.PSChildName; ProfileImagePath = $p.ProfileImagePath }
}
```
Expected result: SID and ProfileImagePath mapping table is displayed.

Step 7: Compare signed-in SID from Step 2 to ProfileImagePath mapping from Step 6.  
Expected result: Signed-in SID maps to expected active user profile path.

Step 8: Check OneDrive process state for known-folder-sync context.  
Action:
```powershell
Get-Process OneDrive -ErrorAction SilentlyContinue | Select-Object Name, Id, StartTime
```
Expected result: OneDrive running state is confirmed.

Step 9 (elevated permission required): Export current shell-folder key as backup before any correction.  
Action:
```powershell
reg export "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" "C:\Temp\Issue3-UserShellFolders-Backup.reg" /y
```
Expected result: Backup `.reg` file is created at `C:\Temp`.

Step 10 (elevated permission required): If Desktop path is incorrect, set Desktop value to baseline `%USERPROFILE%\Desktop`.  
Action:
```powershell
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name Desktop -Value "%USERPROFILE%\Desktop"
```
Expected result: Desktop registry value updates successfully.

Step 11: Sign out the affected user session.  
Action:
```powershell
shutdown /l
```
Expected result: User session logs out cleanly.

Step 12: Sign in with the same user account.  
Expected result: User session starts and desktop loads.

Step 13: Recheck Desktop file visibility after sign-in.  
Action:
```powershell
Get-ChildItem -Path ([Environment]::GetFolderPath('Desktop')) -Force -ErrorAction SilentlyContinue | Select-Object -First 20 FullName
```
Expected result: Expected desktop shortcuts/files are visible.

Step 14: Compare outcome against one unaffected control endpoint.  
Expected result: Affected endpoint now aligns with control endpoint behavior.

## 3) Verification (Before Closure)
1. Signed-in SID maps to expected ProfileImagePath.  
2. Desktop shell path resolves to expected baseline path.  
3. Expected desktop shortcuts/files are visible to the user.  
4. User confirms issue is resolved after one full sign-out/sign-in cycle.  
5. No new related incident ticket is opened for same endpoint within next business cycle.

## 4) Rollback (Immediately Actionable)
1. Action (elevated permission required): Import backup shell-folder registry file created in Step 9.  
Command:
```powershell
reg import "C:\Temp\Issue3-UserShellFolders-Backup.reg"
```
Expected result: Prior shell-folder configuration is restored.

2. Action: Sign out the user session.  
Command:
```powershell
shutdown /l
```
Expected result: Current user session ends.

3. Action: Sign in with the same user account.  
Expected result: Desktop returns to pre-change behavior.

4. Action: Record rollback in incident ticket and stop further endpoint changes.  
Expected result: Endpoint is returned to prior state and escalation is ready.

5. Action: Escalate to L3 endpoint engineering with collected outputs from Steps 2, 3, 6, and 13.  
Expected result: Advanced investigation starts with required evidence.

## 5) Notes
- Edge case: User may be on a temporary profile; path checks can appear valid while profile persistence fails.
- Edge case: OneDrive not running may hide synced desktop content until client starts.
- Warning: Do not edit `ProfileList` keys directly without L3 approval.
- Warning: Always export backup before changing shell-folder values.
- Related incidents: Floor 6 login slowness and Friday app rollout incidents may overlap with this symptom.
