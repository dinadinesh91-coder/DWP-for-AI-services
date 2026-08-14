# Preventive Measures: Issue 3 Missing Desktop Shortcuts

Version: v1.0  
Date: 2026-08-14  
Runbook reference: floor6-issue3-runbook-desktop-shortcuts-v1.md

## Issue Analysis Summary
Most-likely pattern was non-destructive desktop path/profile drift after Win11 migration and Friday changes, not confirmed mass file deletion.

## Preventive Controls
1. Post-migration profile-integrity gate.
- Control: Validate SID-to-profile mapping and Desktop shell path before business start.
- Why: Detects stale profile mapping early.
- Runbook link: Matches SID/path checks and correction flow.

2. Desktop baseline health check.
- Control: Compare expected shortcut baseline and path resolution on pilot endpoints after migration.
- Why: Finds visibility drift before full user impact.
- Runbook link: Aligns with Desktop/Public Desktop verification steps.

3. OneDrive KFM readiness check.
- Control: Confirm OneDrive process and desktop sync state post-cutover.
- Why: Prevents false "missing files" signals from sync lag.
- Runbook link: Mirrors KFM/OneDrive check step.

4. Safe-change registry discipline.
- Control: Require backup export before any shell-folder value change.
- Why: Enables quick restoration if correction worsens state.
- Runbook link: Uses explicit backup and rollback import steps.

5. Control-device comparison requirement.
- Control: Always compare one affected endpoint to one unaffected endpoint before closure.
- Why: Distinguishes user-specific drift from broad policy failure.
- Runbook link: Matches final comparison and verification logic.

## Ownership
- Endpoint Engineering: migration quality gates and profile integrity checks
- Intune Team: policy conflict prevention and baseline enforcement
- Service Desk: first-response path classification and escalation
