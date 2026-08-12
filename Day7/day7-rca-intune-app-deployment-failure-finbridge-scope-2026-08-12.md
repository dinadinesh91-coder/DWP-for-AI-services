# RCA: Intune Application Deployment Failure (FinBridge Scope)

Date of RCA: 2026-08-12
Incident evidence window reviewed: 2024-03-15 10:01:00 to 11:02:32

## 1. Executive Summary

A subset of users could not deploy FinBridge v3.0 through Intune. Evidence from the supplied incident logs shows FinBridge v3.0 deployment was targeted, executed in SYSTEM context, and failed repeatedly with MSI return code 1603, followed by detection result Not detected. The primary root cause is repeatable installer runtime failure on affected endpoints during FinBridge v3.0 install execution.

## 2. Business Impact

- Affected users were unable to complete app deployment during the incident window.
- Service desk load increased due to repeated failed retries.
- Repeated retry cycles (every 60 minutes) extended user impact until manual intervention.

## 3. Evidence Reviewed

Chronological evidence from supplied logs:

- 2024-03-15 10:01:00 AgentExecutor Starting app install: finbridgeV3.0
- 2024-03-15 10:01:01 AppInstaller Install context: SYSTEM
- 2024-03-15 10:01:02 AppInstaller Package: finbridge.intunewin
- 2024-03-15 10:01:03 AppInstaller Install command: msiexec /i finbridge.msi /quiet
- 2024-03-15 10:01:44 AppInstaller Return code: 1603
- 2024-03-15 10:01:44 AppInstaller Install failed. Return code 1603.
- 2024-03-15 10:01:45 DetectionRule Running detection: registry check
- 2024-03-15 10:01:45 DetectionRule Key: HKLM\SOFTWARE\finbridgev3.0\finbridge\3.0
- 2024-03-15 10:01:45 DetectionRule Value: not found
- 2024-03-15 10:01:46 DetectionRule Detection result: Not detected
- 2024-03-15 10:01:47 AgentExecutor App install result: Failed
- 2024-03-15 10:01:47 AgentExecutor Retry scheduled: 60 minutes
- 2024-03-15 11:01:47 AgentExecutor Retry attempt 1: finbridgeV3.0
- 2024-03-15 11:01:48 AppInstaller Install command: msiexec /i finbridge.msi /quiet
- 2024-03-15 11:02:31 AppInstaller Return code: 1603
- 2024-03-15 11:02:32 AgentExecutor Retry 1 failed. Next retry: 60 minutes

## 4. Root Cause Statement

Primary root cause:

- FinBridge v3.0 installer runtime failure on affected endpoints: `msiexec /i finbridge.msi /quiet` executed in SYSTEM context but returned MSI 1603 on initial run and on retry, preventing successful installation.

Secondary technical root cause:

- Detection remained Not detected after both attempts because installation did not complete successfully, and/or the configured registry detection path/value was not present post-attempt.

## 5. Contributing Factors

- Detection rule returned key/value not found at `HKLM\SOFTWARE\finbridgev3.0\finbridge\3.0`, which is consistent with failed install state and may also indicate detection key path/value design drift if installer writes elsewhere.
- Automatic retry behavior prolonged repeated failures without immediate stop condition.
- Limited first-failure telemetry in the supplied snippet (no MSI verbose detail) delayed direct pinpointing of the exact 1603 sub-cause.

## 6. What Did Not Cause This (Based on Available Evidence)

- Intune agent outage is unlikely: agent executed install, detection, and retry flow correctly.
- Immediate content download failure is unlikely in this evidence set: installer command reached execution and returned MSI runtime code.
- Pure assignment miss is unlikely for this affected endpoint: app execution was initiated and retried by AgentExecutor.

## 7. Corrective Actions (Immediate)

1. Stabilize impacted rollout scope
- Pause further FinBridge v3.0 expansion to new cohorts until 1603 sub-cause is validated and remediated.
- Keep currently healthy cohorts unchanged to avoid unnecessary rollback noise.

2. Address installer runtime failure (priority)
- On one representative failed endpoint, rerun install with MSI verbose logging and capture exact failing action for return code 1603.
- Check pending reboot, existing product conflicts, locked files, permissions, disk space, and endpoint security blocking during install window.

3. Validate package and command integrity
- Confirm `finbridge.intunewin` contains `finbridge.msi` at expected path and that command line parameters match vendor deployment guidance.

4. Validate detection correctness
- Confirm detection rule matches the exact registry path/value created by a known-good FinBridge v3.0 install.

## 8. Preventive Actions (Systemic)

1. Pre-deployment install gate
- Require successful SYSTEM-context install plus uninstall validation on at least 3 pilot devices before broad assignment.

2. Assignment safety controls
- Use ringed static groups for first wave and require peer review for include and exclude logic before expanding to dynamic scope.

3. Fast-fail alerting
- Create alert when install return code 1603 exceeds 3 percent in any ring over 2 hours.
- Auto-hold next assignment wave pending engineer review.

4. Detection rule quality check
- Enforce a pre-production check that detection returns detected on a known-good pilot device and not detected on a clean device.

5. Incident evidence checklist
- Require timestamp-matched proof for app identity, package identity, command line, return code, and detection result in all deployment incidents.

## 9. Verification Criteria for Closure

- Test deployment of intended app succeeds on at least 5 previously affected devices.
- Failure rate for intended app remains below 2 percent for 24 hours in impacted ring.
- Detection status reports Installed for validated devices using the finalized detection rule.

## 10. Final RCA Conclusion

The incident was caused by repeatable FinBridge v3.0 installer runtime failure (MSI 1603) on affected endpoints, with subsequent detection Not detected and retry-loop behavior extending impact. Preventing recurrence requires resolving the MSI 1603 sub-cause, validating packaging and command integrity, and confirming detection rule correctness before further rollout expansion.