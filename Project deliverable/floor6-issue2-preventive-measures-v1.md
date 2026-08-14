# Preventive Measures: Issue 2 Copilot Potential Unauthorized Matter Access

Version: v1.0  
Date: 2026-08-14  
Runbook reference: floor6-issue2-runbook-copilot-security-v1.md

## Issue Analysis Summary
User reported Copilot surfaced matter content believed to be unauthorized. Most-likely explanation under analysis is broader-than-expected source permissions, with other governance and identity hypotheses also considered.

## Preventive Controls
1. Scheduled legal-content access recertification.
- Control: Monthly review and approval of access to sensitive matter repositories.
- Why: Shrinks risk of excessive inherited access.
- Runbook link: Supports effective-access validation step.

2. Post-migration membership integrity check.
- Control: Validate security group memberships after migration cutover.
- Why: Prevents unintended access expansion.
- Runbook link: Supports group-based access-path checks.

3. Sensitivity-label and repository-permission gate.
- Control: Require label/ACL validation before enabling broad Copilot usage on legal repositories.
- Why: Prevents over-broad retrieval surface.
- Runbook link: Supports protection-setting validation step.

4. First-contact evidence capture standard.
- Control: Mandatory service desk capture of prompt, response, timestamp, screenshot, and matter ID.
- Why: Preserves incident-grade evidence.
- Runbook link: Matches evidence intake step.

5. Security-first triage policy.
- Control: Enforce "security incident until disproven" for unauthorized Copilot retrieval reports.
- Why: Prevents under-classification and delayed containment.
- Runbook link: Mirrors immediate escalation workflow.

## Ownership
- Security Operations: incident governance and closure authority
- Legal IT/Data Protection: access model and content-governance controls
- Service Desk: evidence quality at intake
