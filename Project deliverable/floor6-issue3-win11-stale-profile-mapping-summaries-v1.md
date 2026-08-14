# Floor 6 Issue 3 Summary: Win11 Stale Profile Mapping

Version: v1.0  
Date: 2026-08-14  
Owner: DWP Engineering

## Audience 1 - Non-technical executive
Your access and data are safe. We found that some Floor 6 desktops were pointing to the wrong user profile after Friday's move, which made shortcuts appear missing. We corrected the profile mapping and confirmed desktop items are returning normally. We are monitoring for repeat cases. No action is needed from you now.

## Audience 2 - Affected end-user team (10 people, non-technical)
Your files are safe. After Friday's Windows update, a few laptops briefly pointed to the wrong desktop location, so shortcuts looked missing even though data was still there. If this happens again, restart your laptop, stay connected to the internet, and wait 10 minutes, then check your desktop again. If it still looks wrong, contact the IT Service Desk with your device name and the time you noticed it.

## Audience 3 - Engineer-to-engineer internal note
Root cause:
- Stale SID-to-profile mapping post-Win11 migration caused desktop resolution to reference a non-active or incorrect profile path for affected users.

Exact action taken:
1. Captured pre-change evidence:
- `HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList`
- `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders`
- User Profile Service events in incident window
2. Validated signed-in SID and expected profile path.
3. Corrected profile mapping/path drift and revalidated Desktop path resolution.
4. Forced policy/sync refresh and user sign-out/sign-in cycle.
5. Confirmed shortcut visibility recovery.

Config detail:
- Primary keys checked:
  - `ProfileList\<SID>\ProfileImagePath`
  - `User Shell Folders\Desktop`
- Expected Desktop target:
  - `%USERPROFILE%\Desktop` or approved OneDrive-managed desktop path per policy baseline.
- Scope:
  - Floor 6 impacted endpoints only.

Verification steps:
1. Signed-in SID maps to active `ProfileImagePath`.
2. Desktop shell path resolves to expected location.
3. Desktop files/shortcuts present at resolved path.
4. No new User Profile Service errors in follow-up check window.
5. User confirms desktop visibility restored.

Preventive action needed:
- Add a post-migration profile-integrity gate before business start:
  - SID-to-profile mapping check
  - Desktop shell path check
  - Desktop content baseline check
  - Auto-flag and hold rollout expansion when drift is detected.
