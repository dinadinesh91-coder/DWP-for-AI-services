# Floor 6 Execution Summary (Three Audiences)

Version: v1.0  
Date: 2026-08-14  
Owner: DWP Engineering

## Audience 1 - Non-technical executive
Your access and data are safe. We identified the likely cause of this morning's sign-in disruption on Floor 6 and have already removed the recent software change from affected devices. Recovery checks are in progress and service is stabilizing. We are also handling the Copilot report as a formal security review. No action is needed from you now.

## Audience 2 - Affected end-user team (10 people, non-technical)
Good news: your files are safe, and we have already started fixing the sign-in issue. A software change from Friday appears to have slowed sign-in for part of Floor 6. Please restart your laptop, stay on network, and try again after 10 minutes. If it still fails or remains slow, contact the IT Service Desk and share your device name and the time it happened.

## Audience 3 - Engineer-to-engineer internal note
Root cause (working, highest probability): Friday Win32 app rollout to Floor 6 created login-path overhead, likely via startup/service initialization and/or IME detect-install retry behavior.

Exact action taken:
1. Set Win32 app assignment intent to uninstall for Floor 6 device group via Graph assign endpoint.
2. Triggered managed-device sync on sampled impacted endpoints.
3. Collected pre/post evidence with the corrected evidence script (registry-based app discovery, profile/perf/system slices, IME signals).

Config detail:
- Graph URI pattern: /beta/deviceAppManagement/mobileApps/{appId}/assign
- Assignment target type: groupAssignmentTarget
- Intent: uninstall
- Scope: Floor 6 device ring only
- Sync endpoint: /beta/deviceManagement/managedDevices/{id}/syncDevice

Verification step:
1. Confirm uninstall intent persisted on app assignment.
2. Confirm sampled endpoints receive policy sync.
3. Validate post-change evidence: reduced profile/perf errors, absence of sustained IME retry loops.
4. Validate service desk trend: sign-in complaints drop through next business cycle.

Preventive action needed:
- Enforce Friday Change Guardrail - Monday Readiness Gate: mandatory 08:00 Monday pilot health test after Friday production app releases (sign-in latency threshold, failure-rate threshold, desktop path integrity check), with automatic assignment pause and on-call page on threshold breach.
