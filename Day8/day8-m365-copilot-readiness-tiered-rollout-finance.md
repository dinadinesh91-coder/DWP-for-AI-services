# Microsoft 365 Copilot Rollout Tiers - Finance

Context date: 2026-08-12  
Scope: Finance department (~200 users), high-sensitivity financial data

This document ranks the existing readiness checklist into rollout tiers based on business risk for Finance.

## MUST complete before rollout (blocking)

These items are hard go/no-go gates. If any are incomplete, rollout should not proceed.

### 1) Permissions and oversharing audit + remediation (Checklist Priority 0)
Why MUST:
- Copilot uses existing Microsoft Graph permissions. If access is overly broad, Copilot will surface sensitive information faster and at greater scale.
- Finance has concentrated high-impact data (payroll, board packs, M&A, client financials), so one permissions gap can become a material confidentiality incident.
- Legacy inherited permissions from the 2019 migration are a known uncertainty and therefore a known exposure.

Blocking evidence required:
- Permissions and sharing-link inventory completed for Finance sites/libraries/folders.
- Inheritance and broad-group review completed; stale/over-broad access removed.
- Oversharing remediations complete (open links removed/expired, high-risk content locked down).
- Role-based access validation complete.
- Formal sign-off by Finance data owner and Security/Compliance.

### 2) Identity baseline controls for Finance users (Checklist Priority 3 - critical subset)
Why MUST:
- Unauthorized access to Finance content is unacceptable; strong identity controls are foundational before AI-assisted discovery is enabled.
- MFA and modern auth reduce account takeover risk, which is amplified when Copilot can summarize broad document sets quickly.

Blocking subset required before rollout:
- MFA enforced for all Finance users and privileged accounts.
- Modern authentication enabled.
- No unsafe legacy auth exceptions for target users.

## SHOULD complete before rollout (high risk if skipped)

These should be done pre-rollout to avoid operational instability or elevated exposure, but could be tightly time-bound exceptions with explicit risk acceptance.

### 1) Copilot licensing prerequisites (Checklist Priority 1)
Why SHOULD (not MUST):
- Licensing is required for users to use Copilot, but this is mostly an entitlement/operations control, not a direct data-governance safeguard.
- Misconfiguration here typically causes service availability issues (users cannot access features) rather than data oversharing.

### 2) Microsoft 365 Apps client readiness (Checklist Priority 2)
Why SHOULD:
- Outdated clients can degrade user experience and supportability.
- Usually creates reliability and adoption risk, not primary confidentiality breach risk.

### 3) Identity hardening remainder (Checklist Priority 3 - non-blocking remainder)
Why SHOULD:
- Conditional Access tuning and break-glass testing should be done before broad rollout where possible.
- If deferred, this should have a dated remediation plan and active risk tracking.

### 4) Sensitivity labelling and information protection (Checklist Priority 4)
Why SHOULD:
- Labels improve durable protection and reduce accidental misuse.
- Critical permissions issues still represent the first-order exposure; labels are a strong second control that should be in place before scale-out.

## CAN complete during/after rollout (lower risk)

These can proceed in parallel with a controlled pilot or early production stages.

### 1) End-user communications and enablement (Checklist Priority 5)
Why CAN:
- Training and communication are essential for adoption quality, but they are not the first technical containment layer.
- Can be iteratively improved with pilot feedback, provided safe-use minimum guidance is issued at pilot start.

### 2) Expanded rollout governance artifacts (from Recommended Rollout Control)
Why CAN (during pilot, before scale):
- Pilot criteria and stage-gates should exist before expansion, but refinements can continue during pilot execution.

## Finance-specific justification: why permissions/oversharing is MUST even if licensing/client checks are simpler

Licensing and client versions are simpler to verify because they are mostly deterministic configuration checks (assigned/not assigned, supported/not supported). Permissions risk is different:

- Impact severity is much higher:
  - Licensing/client gaps usually cause failed access or degraded experience.
  - Permissions gaps can cause confidential Finance data disclosure.

- Blast radius is larger with Copilot:
  - Copilot aggregates and summarizes across accessible content quickly.
  - A single over-broad group or sharing link can expose many sensitive documents in one interaction.

- Detection is harder after rollout:
  - Mis-licensing is visible quickly through user errors.
  - Oversharing may remain silent until sensitive content appears in prompts or outputs.

- Remediation urgency is asymmetric:
  - Licensing/client fixes are usually straightforward operational tasks.
  - Permission cleanup can require cross-owner validation and careful access redesign.

Risk framing for Finance:
- Data exposure risk can be approximated as: Risk = Likelihood x Impact x Discoverability-at-scale.
- Copilot materially increases discoverability-at-scale for already-permitted content.
- Therefore, permission correctness is the primary blocking control.

## Practical gate recommendation for this Finance rollout

Rollout gate order:
1. Complete MUST tier and obtain sign-off.
2. Complete SHOULD tier or document dated exceptions with risk acceptance.
3. Start controlled pilot.
4. Complete CAN items iteratively during pilot and before broad rollout expansion.
