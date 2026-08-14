# Day 10 Floor 6 Incident: Triage, Copilot Escalation, Login Differential, and Immediate Action

Date: 2026-08-14  
Analyst: DWP Engineer  
Evidence boundary: This document starts from scope facts only. Where checks are listed, they are the first verification actions to run.

## Scope Facts
- Floor 6 Legal, 45 users
- Recently migrated to Windows 11 and enrolled in Intune
- Monday morning: at least a dozen users cannot log in or login is very slow
- One user reports Copilot surfaced a client matter she says she never had access to
- One user reports desktop shortcuts vanished
- New document management app deployed to Floor 6 on Friday afternoon

## 1) Triage: First 30 Minutes (Urgency Ordered)

### Priority 1 (0 to 5 min): Potential unauthorized matter exposure via Copilot
What to check first:
1. Capture exact report details: user, timestamp, prompt used, response snippet, and any screenshot.
2. Identify the exact matter/document and source repository location.
3. Confirm effective permissions for that user on that content path.

Why first:
- This is a potential security and confidentiality incident, not a standard support queue item.

### Priority 2 (0 to 10 min): Login failure and severe slowness containment
What to check first:
1. Confirm blast radius by user and device count.
2. Determine if problem is Floor 6 only or cross-floor.
3. Time-align first failures against Friday deployment and Monday start of business.

Why second:
- Highest immediate business interruption for Legal operations.

### Priority 3 (10 to 20 min): Friday change correlation
What to check first:
1. Verify affected devices are in Friday app assignment group.
2. Verify unaffected comparison devices are not in that assignment.
3. Check whether app install/detection retries are present on affected set.

Why third:
- Fastest path to a reversible technical action if change correlation is confirmed.

### Priority 4 (20 to 30 min): Missing shortcuts classification
What to check first:
1. Determine whether files are missing versus shortcuts/paths moved.
2. Compare user Desktop and Public Desktop shortcut counts on affected vs unaffected devices.

Why fourth:
- Often a secondary symptom of profile/logon processing and lower urgency than security signal plus login outage.

## 2) The Copilot Incident: Correct Handling

### What it actually is
This is a potential unauthorized information exposure signal requiring incident response, not a routine "AI behavior" support ticket.

### What not to do
- Do not close it as "AI weirdness."
- Do not delay escalation pending full login root cause.
- Do not ask user to repeatedly retry prompts before evidence capture.

### Two-sentence escalation draft
We have a potential unauthorized data exposure report involving Copilot retrieving a legal matter for a user who states she has never had access to that content. Please open a priority security investigation now with Security Operations, Legal IT, and Data Protection to validate effective permissions and retrieval audit evidence before wider communications.

## 3) Ranked Differential for Login and Performance (Most Probable First)

### 1) Friday app deployment regression on Floor 6
Why this fits scope facts:
- Exact population match: rollout targeted this floor.
- Exact timing match: Friday rollout and Monday morning failure cluster.
- Symptom fit: long login and apparent login failures are consistent with startup extension, service initialization, or install retry behavior.

Single fastest check:
- On three affected devices, compare app install timestamp/version and IME install activity to first login slowdown time, plus one unaffected control device.

Evidence confirms deployment as cause:
- Affected devices all show the new app deployed before symptom onset.
- IME logs/events show retry/failure loops or startup overhead tied to app components.
- Control device outside assignment lacks same signal pattern.

Evidence rules out deployment as cause:
- Same login failure pattern appears on devices without app assignment/install.
- Symptom onset precedes app deployment timestamps.

### 2) Intune assignment or detection rule loop specific to Floor 6
Why this fits scope facts:
- Recent Intune onboarding increases risk of mis-scoped requirement or detection logic.
- Retry loops can severely delay logon experience.

Single fastest check:
- Review Intune app install status for affected group and look for repeated failed/retried states.

### 3) Win11 profile migration side effects
Why this fits scope facts:
- Recent OS migration can surface profile load delays and shell path inconsistencies.
- Aligns with both login slowness and missing shortcuts.

Single fastest check:
- Check recent User Profile Service events plus Desktop path resolution on one affected endpoint.

### 4) Identity token/session state drift after migration
Why this fits scope facts:
- "Cannot log in" can reflect auth/session refresh failures after migration.
- May impact subset of users rather than full floor.

Single fastest check:
- Check Entra sign-in outcomes for sampled affected user-device pairs during incident window.

### 5) Monday morning shared-service contention
Why this fits scope facts:
- Monday surge can produce partial authentication and profile-service latency.

Single fastest check:
- Compare sign-in latency/failure rates across multiple floors in same time slice.

## 3a) Build the Check: AI-Generated Script and Hand-Corrected Script

One-line correction note:
I replaced Win32_Product usage with uninstall-registry queries because Win32_Product can trigger MSI self-repair and distort incident evidence while adding avoidable endpoint impact.

Full script files:
- AI-first: [Day10/day10-floor6-login-check-ai-first.ps1](Day10/day10-floor6-login-check-ai-first.ps1)
- Corrected: [Day10/day10-floor6-login-check-corrected.ps1](Day10/day10-floor6-login-check-corrected.ps1)

Side-by-side core change:

| AI-first (before) | Hand-corrected (after) |
|---|---|
| ```powershell
$app = Get-WmiObject -Class Win32_Product | Where-Object {
		$_.Name -like "*$AppDisplayName*"
} | Select-Object -First 1 Name, Version, InstallDate
``` | ```powershell
$appEvidence = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
															 "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
															 "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" |
		Where-Object { $_.DisplayName -and $_.DisplayName -like "*$AppDisplayName*" } |
		Select-Object DisplayName, DisplayVersion, Publisher, InstallDate
``` |

Dry-run command:
```powershell
.\day10-floor6-login-check-corrected.ps1 -AppDisplayName "FinBridge Document Management" -LookbackHours 72 -DryRun
```

Collection command:
```powershell
.\day10-floor6-login-check-corrected.ps1 -AppDisplayName "FinBridge Document Management" -LookbackHours 72 -OutputPath "C:\Temp\Day10-Floor6Evidence.json"
```

Structured output produced:
- JSON containing app install evidence, profile/performance/system event slices, related services/tasks, shortcut state, IME app signals, and hypothesis flags for actioning by another engineer.

## 4) Immediate Fix and Message to Floor 6

### Working most-likely cause for first mitigation
Based on scope timing and targeting, the first mitigation candidate is Friday app deployment regression while validation continues.

### Technical action now (actual rollback command pattern)

```powershell
Connect-MgGraph -Scopes "DeviceManagementApps.ReadWrite.All","Group.Read.All"

$appId = "<WIN32_APP_ID>"
$floor6DeviceGroupId = "<FLOOR6_DEVICE_GROUP_ID>"

$assignmentBody = @{
	mobileAppAssignments = @(
		@{
			"@odata.type" = "#microsoft.graph.mobileAppAssignment"
			intent = "uninstall"
			target = @{
				"@odata.type" = "#microsoft.graph.groupAssignmentTarget"
				groupId = $floor6DeviceGroupId
			}
		}
	)
}

Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/$appId/assign" -Body ($assignmentBody | ConvertTo-Json -Depth 8)
```

Optional acceleration for sampled managed devices:

```powershell
$managedDeviceId = "<MANAGED_DEVICE_ID>"
Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$managedDeviceId/syncDevice"
```

### Plain-language note to Floor 6
We found a likely link between Friday's software change and this morning's sign-in and desktop issues for Floor 6, and we are now removing that change from affected devices. Your files are not being deleted, and we will post updates every 30 minutes while we confirm recovery device by device.
