# Day 10 Issue 2: Copilot Potential Unauthorized Matter Access (Floor 6)

Date: 2026-08-14  
Analyst: DWP Engineer  
Evidence boundary: Scope facts only from initial Slack report.

## Scope Facts Used
- One paralegal reports Copilot surfaced a client matter she believes she never had access to
- Report arrived during broader Floor 6 incident window

## Incident Classification
This is a potential security/confidentiality signal, not a routine support defect.

## Immediate Triage Focus
What to check first:
1. Preserve evidence: reporter identity, timestamp, exact prompt/response, screenshot, matter reference.
2. Validate effective permissions in source repositories for that user and matter.
3. Open formal security/data-governance escalation (SOC + Legal IT + Data Protection).

Why first:
- If true, this is potential unauthorized information exposure.
- Delay increases legal and regulatory risk.

## Most Likely Explanations (No Final Commitment)

### 1) Underlying source permissions are broader than expected
Why it fits:
- Copilot retrieval normally follows existing access controls.

Fastest check:
- Check whether the user account has direct or transitive access to the matter source.

### 2) Group membership drift after migration changed access scope
Why it fits:
- Recent migration/enrollment can alter effective memberships or inherited access.

Fastest check:
- Compare user group memberships before and after migration cutover.

### 3) Labeling/governance gap allows over-broad retrieval surface
Why it fits:
- If matter content is not correctly restricted/labeled, retrieval scope can be too broad.

Fastest check:
- Inspect sensitivity label and repository permissions on the reported matter location.

### 4) User identity confusion (wrong account/session context)
Why it fits:
- Shared devices/sessions can cause mistaken identity context.

Fastest check:
- Validate signed-in account/session at incident timestamp.

### 5) User misinterpretation of similar matter naming/content
Why it fits:
- Similar titles can be mistaken for restricted matters.

Fastest check:
- Verify exact document ID/location and compare with reported matter name.

## Current Position
- Treat as active security signal until disproven.
- Do not close as "AI weirdness" without permission and audit validation.
