# Floor 6 Issue 2: Copilot Incident (Security Signal Handling)

Version: v3.0  
Date: 2026-08-14  
Author: DWP Engineer

## Scope Fact Used
- Paralegal reports Copilot surfaced a client matter she says she never had access to.

## What This Is
A potential unauthorized information exposure signal requiring security incident handling, not a normal support ticket and not a product-quirk closure.

## First 30 Minutes Triage (This Issue)
1. Preserve evidence immediately: user, time, prompt text, response snippet, screenshot, matter/document ID.
Why: Prevents evidence loss and supports audit trail.

2. Identify exact source location for returned content.
Why: Access validation must be run against real source object.

3. Validate effective permissions for reporting user at incident time.
Why: Determines whether access was valid, drifted, or unauthorized.

4. Open security incident channel with Security Operations, Legal IT, and Data Protection.
Why: Potential legal confidentiality exposure cannot wait for desktop triage completion.

## What NOT To Do
- Do not close as "AI weirdness."
- Do not delay escalation pending login root-cause.
- Do not rely on memory or user recollection without preserving exact response evidence.

## Two-Sentence Escalation Draft
We have a potential unauthorized information exposure report involving Copilot returning legal matter content for a user who states she has never had access to that matter. Please initiate priority security triage with Security Operations, Legal IT, and Data Protection to validate effective permissions, retrieval telemetry, and governance controls before broader communication.
