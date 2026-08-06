# Personal AI Usage Charter (DWP Engineer, Public AI Assistants)

Version: Personal working standard (not a substitute for official DWP policy)
Date: 2026-08-04

## Purpose
Use public AI assistants to improve speed and quality in desktop/endpoint engineering while protecting users, systems, and DWP data.

## 1) Appropriate DWP Tasks for Public LLM Help
Use public AI only for low-risk, non-sensitive work where prompts can be fully sanitized.

- Drafting and improving:
  - User-facing communications (incident updates, planned-change notices, knowledge articles) with no personal or case details.
  - Standard operating steps in plain English.
  - Troubleshooting checklists for generic issues (slow boot, Outlook launch delays, profile corruption symptoms, patch failures).
- Technical assistance on generic content:
  - PowerShell/Bash one-liners for common endpoint admin tasks using placeholder values.
  - Script refactoring for readability, logging, error handling, and idempotency.
  - Command explanations (for example, what a registry key, service, or event ID typically means).
  - Comparison of tooling approaches (for example, Intune vs local script logic, detection/remediation patterns), without tenant specifics.
- Learning and preparation:
  - "What to check first" sequences for desktop incidents.
  - Test plan templates for pilot deployments and rollback planning.
  - Documentation structures for runbooks and post-incident reviews.

Rule of thumb: If the request can be understood without naming a real user, real machine, real tenant detail, or real business case, it is usually suitable.

## 2) Tasks That Are Not Appropriate
Do not use public AI for anything that exposes protected information or could directly alter production without controlled review.

- Never submit:
  - End-user identifiers, contact details, NI numbers, addresses, payroll or case information, screenshots containing user data.
  - Credentials or secrets (passwords, API keys, tokens, private certificates, recovery keys).
  - Internal architecture, security controls, vulnerability details, incident evidence, or unpublished configurations.
  - Device inventories, hostnames, IP ranges, tenant IDs, domain names, ticket exports, or raw logs with identifiable data.
- Never delegate decision authority:
  - Final root-cause conclusions for security incidents.
  - Risk acceptance decisions.
  - Approval wording that implies policy/legal sign-off.
- Never execute blindly:
  - AI-generated scripts directly in production.
  - Registry/system changes across fleet without test and rollback controls.

## 3) Data-Handling Rule (End-User PII and Credentials)
**Zero-sensitive-data rule:** I will not paste end-user PII, credentials, secrets, or internal-only operational data into any public AI assistant.

- Minimum safe prompt standard:
  - Replace names, usernames, emails, hostnames, and IDs with placeholders like `<USER>`, `<DEVICE>`, `<TENANT>`.
  - Strip metadata from logs and screenshots before sharing; if in doubt, do not share.
  - Use synthetic examples where possible.
  - Keep prompts to the least detail required to get useful help.
  - Assume prompts and outputs may be retained externally.
- Hard stop:
  - If a task requires real user/case/system identifiers to be useful, do not use public AI for that task.
  - Move to approved internal tooling/process instead.

## 4) Personal Generate-Then-Verify Rule (Scripts and System Changes)
AI can generate drafts; I remain accountable for safety and correctness.

- Generate:
  - Ask AI for a draft script/change plan with explicit assumptions, dependencies, and rollback steps.
  - Require comments, logging, and `-WhatIf`/dry-run capability where feasible.
- Verify before any live use:
  - Read every line; remove unknown commands and over-privileged actions.
  - Validate against official Microsoft/DWP guidance and current endpoint baseline.
  - Test in isolated non-production environment first.
  - Confirm idempotency, error handling, and expected exit codes.
  - Peer review for medium/high-impact changes.
  - Prepare rollback, success criteria, and monitoring checks.
- Deploy safely:
  - Pilot to a small, representative device group.
  - Time-box and monitor for regressions (boot time, Outlook launch, CPU/memory, policy compliance).
  - Record what was changed, why, and outcome in ticket/change notes.
  - Stop rollout immediately on unexpected impact.

## Personal Accountability Statement
I use public AI as a drafting assistant, not an authority. I protect user data first, validate all technical output, and keep human judgment in control of endpoint changes.
