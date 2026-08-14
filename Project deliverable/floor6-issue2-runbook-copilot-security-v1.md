# Runbook: Issue 2 Copilot Potential Unauthorized Matter Access

Version: v1.0  
Date: 2026-08-14  
Owner: DWP Service Desk

## Objective
Handle Copilot-reported potential unauthorized matter exposure as a security incident from first report through validated closure.

## Prerequisites
1. Incident ticket opened and security severity assigned.
2. Access to Security Operations, Legal IT, and Data Protection escalation channels.
3. Ability to collect and store evidence securely.
4. Access to permission and content-location administration views (to confirm exact system roles).

## Procedure
1. Capture report details: user, time, prompt, response, screenshot, matter reference.
Expected result: Incident record has complete first-contact evidence.

2. Open security escalation to Security Operations, Legal IT, and Data Protection.
Expected result: Security incident workflow is active.

3. Identify the exact source object/location referenced by Copilot output.
Expected result: Source file/location is confirmed.

4. Validate reporting user's effective access rights to the source object.
Expected result: Direct/transitive access path is documented.

5. Validate content protection settings and repository permissions.
Expected result: Labeling/permission state is documented.

6. Confirm session/account context at reported timestamp.
Expected result: Account context mismatch is confirmed or ruled out.

7. Record root-cause decision and corrective action plan.
Expected result: Closure criteria and ownership are documented.

## Verification
1. Cause is confirmed with evidence.
2. Excessive access (if found) is removed.
3. Security stakeholders approve closure.

## Rollback
1. If corrective permission change blocks legitimate users, restore prior permissions only for approved legal-access group.
2. Re-test access for approved and non-approved test users.
3. Keep incident open and escalate to Legal IT owner if permission model remains ambiguous.

## Notes
- Do not close as "AI weirdness".
- Keep this incident separate from unrelated login/performance streams.
- Mark any missing evidence as "to confirm".
