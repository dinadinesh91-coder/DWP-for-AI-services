# Microsoft 365 Copilot Readiness Checklist - Finance Department

Department scope: Finance (~200 users), financial services data sensitivity, Microsoft 365 E5 in place, Copilot add-on not yet assigned.

Read this first:
- This checklist is ordered by risk, not convenience.
- Do not enable Copilot for Finance users until Priority 0 is complete and signed off.

## Priority 0 (Highest Priority): Permissions and Oversharing Risk Controls

Reason for highest priority:
- Finance data includes payroll, board packs, M&A documents, and client financial data.
- SharePoint/OneDrive permissions were inherited from a 2019 migration and not fully audited since.
- Copilot responses reflect what users are already allowed to access, so excessive access rights become immediate exposure risk.

### 0.1 Tenant-wide and Finance scope inventory
- [ ] Export current permissions for all Finance SharePoint sites, document libraries, and key folders.
- [ ] Export sharing links (Anyone links, org-wide links, direct external shares) for Finance-owned content.
- [ ] Produce list of high-sensitivity content locations: payroll, board, M&A, client finance.
- [ ] Map owners for each high-sensitivity site/library.

### 0.2 Inheritance and broken permission review
- [ ] Identify all locations with unique permissions created since the 2019 migration.
- [ ] Review broad groups (Everyone except external users, All Company, large legacy groups) and remove where not business-justified.
- [ ] Remove stale access (users who changed role/left team still present).
- [ ] Validate guest/external access is disabled or tightly scoped for Finance confidential libraries.

### 0.3 Oversharing remediation actions
- [ ] Remove or expire open sharing links that are no longer needed.
- [ ] Restrict high-risk libraries to least-privilege groups only.
- [ ] Move highly confidential documents into locked-down libraries where needed.
- [ ] Confirm default link type is not overly permissive for Finance sites.

### 0.4 Validation before Copilot enablement
- [ ] Run sample access tests for representative Finance roles (analyst, manager, payroll, leadership support).
- [ ] Confirm each role can access only intended content, and cannot discover restricted payroll/M&A/board documents.
- [ ] Record sign-off from Finance data owner and Security/Compliance owner.
- [ ] Set go/no-go decision: Copilot enablement blocked until all above checks are complete.

## Priority 1: Licensing Prerequisites

- [ ] Confirm all target users have Microsoft 365 E5 active and healthy.
- [ ] Purchase/provision required Microsoft 365 Copilot licenses for pilot and full Finance cohort.
- [ ] Assign Copilot licenses first to a controlled pilot group (not all 200 at once).
- [ ] Confirm license assignment propagation and service health before pilot start.

## Priority 2: Microsoft 365 Apps Client Readiness

- [ ] Confirm target devices use supported Microsoft 365 Apps for enterprise builds on update channels approved by IT.
- [ ] Verify Word, Excel, PowerPoint, Outlook, and Teams clients are updated to supported versions.
- [ ] Check sign-in state is healthy in Office apps (no recurring activation/auth prompts).
- [ ] Validate pilot devices have recent updates and normal app launch performance.

## Priority 3: Identity and MFA Readiness

- [ ] Confirm all Finance users have modern authentication enabled.
- [ ] Confirm MFA is enforced for all Finance accounts, including privileged accounts.
- [ ] Remove/secure legacy auth paths and high-risk exclusions.
- [ ] Validate Conditional Access policies support normal Finance workflows without unsafe bypasses.
- [ ] Verify break-glass process exists and is tested for account lockout scenarios.

## Priority 4: Sensitivity Labelling and Information Protection

- [ ] Confirm sensitivity labels exist for Finance classifications (for example: Public, Internal, Confidential, Highly Confidential-Finance).
- [ ] Ensure labels are published to Finance users and available in Office apps.
- [ ] Apply mandatory or recommended labels for high-risk content locations.
- [ ] Validate label protections align with business need (encryption, access restrictions, external sharing controls).
- [ ] Spot-check existing payroll, board, M&A, and client files for correct label coverage.

## Priority 5: End-User Communications and Enablement

- [ ] Publish a Finance-specific launch notice: what Copilot can do, what it cannot do, and data-handling expectations.
- [ ] Provide a one-page safe-use guide (prompt hygiene, no copying sensitive outputs to uncontrolled channels, verify outputs before use).
- [ ] Deliver short role-based training sessions (analyst, manager, executive support) with real Finance scenarios.
- [ ] Publish support path: where to get help, how to report incorrect access/results, expected response times.
- [ ] Run pilot feedback survey after week 1 and feed findings into permission/labelling remediation backlog.

## Recommended Rollout Control

- [ ] Pilot size agreed (for example 15-25 users across Finance subfunctions).
- [ ] Pilot entry criteria met: Priority 0 complete and signed off.
- [ ] Pilot success criteria defined: no critical oversharing findings, stable auth, acceptable user experience.
- [ ] Stage-gate decision recorded before expanding beyond pilot.

## Sign-Off

- [ ] Finance Data Owner sign-off
- [ ] Security/Compliance sign-off
- [ ] EUC/IT Operations sign-off
- [ ] Service Desk readiness confirmed
- [ ] Final go-live approval recorded