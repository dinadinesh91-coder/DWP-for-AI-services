# Preventive Measures: Issue 1 Login Failure / Sign-In Slowness

Version: v1.0  
Date: 2026-08-14  
Runbook reference: floor6-runbook-login-app-regression-v4.md

## Issue Analysis Summary
Most-likely pattern was app-regression impact after Friday deployment to Floor 6, with Monday sign-in disruption and ring-specific clustering.

## Preventive Controls
1. Friday Change Guardrail Monday Readiness Gate.
- Control: Require Monday 08:00 pilot checks before broad rollout.
- Why: Detects delayed sign-in regressions before user peak.
- Runbook link: Supports pre/post evidence and pilot-first validation steps.

2. Ring-based progressive deployment enforcement.
- Control: Deploy to pilot ring first, hold broad ring until sign-in thresholds pass.
- Why: Limits blast radius.
- Runbook link: Aligns with sampled-device sync and pilot recovery checks.

3. Mandatory uninstall rollback playbook readiness.
- Control: Keep tested uninstall assignment command path ready for every Win32 release.
- Why: Reduces mean time to recover.
- Runbook link: Mirrors uninstall + sync procedure.

4. IME retry-loop monitoring.
- Control: Alert on repeated app detection/install retries on affected ring.
- Why: Early warning for startup/logon degradation.
- Runbook link: Matches evidence capture signals.

5. Change approval quality gate.
- Control: Block production release if detection rules or dependencies are unvalidated.
- Why: Prevents mis-scoped or looping deployments.
- Runbook link: Reduces need for emergency rollback path.

## Ownership
- Endpoint Engineering: deployment quality and rollback readiness
- Intune Platform Team: ring governance and telemetry alerts
- Service Desk: early detection and incident routing
