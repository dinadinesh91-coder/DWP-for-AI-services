# L2 Technical Article: Floor 6 Copilot Potential Unauthorized Matter Access

Version: v1.0  
Date: 2026-08-14  
Audience: L2/L3 engineers and incident responders  
Related runbook: floor6-issue2-runbook-copilot-security-v1.md

## Incident Classification
**Any report of unauthorized content access via Copilot must be treated as a potential confidentiality/data-protection incident until disproven.**

Do not treat as routine support defect. Do not close as "AI weirdness". Escalate immediately.

## When to Use This Article

Use this article when:
- A user reports Copilot returned legal matter, client, or confidential content they believe they were not authorized to access
- The report occurs during the Monday morning Floor 6 incident window or any other timeframe
- The user indicates Copilot provided unexpected, sensitive, or out-of-scope information

## Immediate Intake (First Contact)

When a user reports a potential unauthorized access incident, capture this evidence:

1. **Reporter identity and contact information**
2. **Exact timestamp** when the user observed the issue
3. **Exact prompt text** the user entered into Copilot
4. **Exact response snippet and screenshot** of Copilot's output
5. **Document/matter details**: title, URL/path, matter identifier, client name
6. **Device context**: device name, signed-in account, session start time
7. **Severity assessment**: Is this a known, approved matter for the user, or completely unexpected?

Store all evidence in the incident ticket—do not discard or edit evidence.

## Containment and Escalation

Immediately open or update a security incident with:
- **Security Operations** (incident classification: potential data breach/confidentiality impact)
- **Legal IT** (matter/content owner perspective)
- **Data Protection/Privacy team** (compliance and legal hold implications)

Do not await confirmation of the cause before escalating. Treat the report as credible.

## Technical Validation Steps (Sequential)

### Step 1: Confirm Exact Source Object
Identify the exact file, document, or content location referenced by Copilot:
- Request URL/file path from the user's screenshot
- Verify the document/matter exists in the repository
- Confirm sensitivity labeling and retention classification

### Step 2: Validate User's Effective Permissions
Check the signed-in user's actual access rights to the source object:

| Permission Level | Check |
|---|---|
| **Direct permission** | Is the user granted direct read/access to this document? |
| **Group membership** | Is the user a member of a security group with access? |
| **Transitive access** | Does the user inherit access through nested groups? |
| **Repository ACL** | Does the content's folder/library ACL include the user or user's group? |

Document the permission path (direct, group name, nested group chain, etc.).

### Step 3: Compare Actual vs. Expected Access Model
Compare the user's actual permissions against the Legal department's access control model:
- Is this matter one the user should access in their role?
- Should the user be in any security groups that would grant this access?
- Is there a mismatch between group membership and expected role permissions?

### Step 4: Check Content Protection Settings
Review the document/matter's protection and governance configuration:
- Sensitivity/classification label applied (Confidential, Restricted, Public, etc.)
- Retention policy enforcement
- Co-authoring or sharing restrictions
- Data Loss Prevention (DLP) policy coverage

### Step 5: Confirm Session/Account Context
Verify the signed-in account at the reported timestamp:
- Is the account the user's own account?
- Was there account delegation or session sharing active?
- Were there recent account/identity changes (migration, SSO refresh, etc.)?
- Check Entra ID sign-in logs for the user/device pair at incident timestamp

### Step 6: Validate Evidence Completeness
Before proceeding to root-cause, confirm all evidence is documented:
- ✓ Exact source object identified
- ✓ User's access rights documented  
- ✓ Actual permissions vs. expected permissions compared
- ✓ Content protection settings recorded
- ✓ Account/session context confirmed at incident time

## Root-Cause Hypothesis Mapping

Based on the runbook, evaluate these causes in order of likelihood:

| Hypothesis | Evidence to Look For | Resolution Path |
|---|---|---|
| **Source permissions broader than expected** | User's groups have wider access than intended; ACLs overly permissive | Review and tighten ACLs; remove user from over-broad groups |
| **Group membership drift post-migration** | User added to security groups during migration without proper validation | Audit group membership changes; remove inappropriate memberships |
| **Content protection gap** | Document lacks sensitivity label or retention policy; visibility not restricted | Apply correct classification labels; enforce DLP rules |
| **Identity/session mismatch** | Wrong account active; delegation/impersonation; Entra sign-in anomaly | Confirm user's own account was signed in; check for sign-in failures |
| **User misinterpretation** | Matter names are similar; user confused valid access with unauthorized | Confirm document title and matter ID; clarify with user |

## Resolution Criteria

The incident can only be closed when ALL of the following are complete:

1. ✓ Exact source object (file, location, matter ID) is confirmed
2. ✓ User's effective access at incident timestamp is documented
3. ✓ Root cause is identified with supporting evidence
4. ✓ Root cause is either resolved (access corrected) or explicitly disproven
5. ✓ Remediation (if needed) is applied: ACLs updated, groups corrected, labels applied
6. ✓ Security stakeholders (Security Ops, Legal IT, Data Protection) approve closure
7. ✓ User is notified through approved communication channel
8. ✓ Preventive action is recorded (access review, policy update, training, etc.)

## What Must NOT Be Done

- ❌ Do not close as "AI weirdness" or assume Copilot has no role
- ❌ Do not delay escalation while other Floor 6 incidents are being worked
- ❌ Do not alter, edit, or discard evidence before incident documentation is complete
- ❌ Do not treat as routine support ticket
- ❌ Do not ask the user to "try again" and see if the problem recurs

## Preventive Actions (Post-Closure)

Once this incident is resolved, implement preventive measures:

1. **Access review cadence**: Run quarterly reviews of access to sensitive legal matters
2. **Post-migration validation**: Confirm all group memberships are correct after future Intune/migration projects
3. **Content governance**: Audit and apply sensitivity labels to all legal matter content before Copilot expansion
4. **Service desk escalation**: Require service desk to capture full Copilot prompt/response evidence at first user contact for any security-related concern
5. **User education**: Provide guidance to Floor 6 users on recognizing and reporting data-access concerns

## Incident Status Tracking

Document the incident progression with these status markers:

- **Reported**: Initial user report received; evidence captured
- **Escalated**: Security, Legal IT, Data Protection teams notified
- **Validating**: Permission and access checks underway
- **Root cause identified**: Cause confirmed; remediation plan documented
- **Remediation in progress**: Access/permissions being corrected
- **Resolved**: All closure criteria met; stakeholder approval obtained
- **Closed**: User notified; preventive action recorded

Do not skip any status—each represents a required validation step.
