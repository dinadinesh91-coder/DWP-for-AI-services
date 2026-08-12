# Day 8 Copilot Ticket Triage - Likely Cause Ranking

Date: 2026-08-12  
Role context: DWP engineer training Copilot support triage

Rule applied throughout:
- Default to non-Copilot causes unless evidence strongly rules them out.
- Genuine Copilot fault is always ranked last.

## Ticket 1
Ticket: Finance lead cannot summarise Q3 board pack in SharePoint, says they can see it themselves.

Likely cause ranking (most probable first):
1. Sensitivity label restriction
2. Permissions/access boundary
3. Data indexing lag
4. License/client prerequisite issue
5. Guest/external sharing limitation
6. Genuine Copilot fault

Fastest check:
- Open the board pack file in SharePoint and check its sensitivity label and protection settings first.

Is this actually a Copilot bug?
- Unclear. The user can manually view the file, but board documents are commonly label-protected in ways that can limit Copilot grounding even when human read access exists.

## Ticket 2
Ticket: New hire started yesterday; Copilot in Outlook knows nothing about recent emails.

Likely cause ranking (most probable first):
1. Data indexing lag
2. License/client prerequisite issue
3. Permissions/access boundary
4. Sensitivity label restriction
5. Guest/external sharing limitation
6. Genuine Copilot fault

Fastest check:
- Confirm whether the user was licensed and signed into Copilot-supported Outlook only recently; if yes, treat as likely indexing warm-up first.

Is this actually a Copilot bug?
- No. New-joiner mailbox and graph context delays are a common non-bug explanation, especially on day one.

## Ticket 3
Ticket: HR manager in Word asks Copilot to pull data from sensitive salary spreadsheet; Copilot says it does not have access.

Likely cause ranking (most probable first):
1. Permissions/access boundary
2. Sensitivity label restriction
3. Data indexing lag
4. License/client prerequisite issue
5. Guest/external sharing limitation
6. Genuine Copilot fault

Fastest check:
- Verify the HR manager has direct permission to that spreadsheet and parent library (including any unique permissions).

Is this actually a Copilot bug?
- No. The explicit no-access response aligns with normal access-boundary enforcement.

## Ticket 4
Ticket: Sales rep in Teams cannot find a client contract shared via guest link from another org.

Likely cause ranking (most probable first):
1. Guest/external sharing limitation
2. Permissions/access boundary
3. Sensitivity label restriction
4. Data indexing lag
5. License/client prerequisite issue
6. Genuine Copilot fault

Fastest check:
- Confirm the contract is only available via cross-tenant guest/external link and not in the rep's home-tenant indexed content.

Is this actually a Copilot bug?
- No. Cross-tenant guest sharing scenarios commonly do not behave like first-party indexed organizational content for Copilot retrieval.

## Ticket 5
Ticket: IT admin says Copilot stopped for whole Finance team this morning; worked yesterday.

Likely cause ranking (most probable first):
1. License/client prerequisite issue
2. Permissions/access boundary
3. Data indexing lag
4. Sensitivity label restriction
5. Guest/external sharing limitation
6. Genuine Copilot fault

Fastest check:
- Check whether Finance users still have Copilot licenses assigned and service plans enabled right now.

Is this actually a Copilot bug?
- Unclear. Team-wide sudden failure can be caused by entitlement changes or policy shifts; only after those checks fail should a platform fault be suspected.

## Ticket 6
Ticket: Manager says Copilot summarised a file they forgot they had access to.

Likely cause ranking (most probable first):
1. Permissions/access boundary
2. Data indexing lag
3. Sensitivity label restriction
4. License/client prerequisite issue
5. Guest/external sharing limitation
6. Genuine Copilot fault

Fastest check:
- Validate the manager's effective permissions on that folder/file in SharePoint or OneDrive.

Is this actually a Copilot bug?
- No. This behavior matches expected Copilot grounding on content the user is already permitted to access.

## Ticket 7
Ticket: Analyst gets generic answers; Copilot does not seem to use internal SharePoint content at all.

Likely cause ranking (most probable first):
1. License/client prerequisite issue
2. Permissions/access boundary
3. Data indexing lag
4. Sensitivity label restriction
5. Guest/external sharing limitation
6. Genuine Copilot fault

Fastest check:
- Verify the analyst is on a supported M365 client/account context with active Copilot license and is not using the wrong tenant/account.

Is this actually a Copilot bug?
- Unclear. This pattern is more often caused by entitlement/client/account-context issues than a core Copilot defect.

## Ticket 8
Ticket: Executive assistant in Outlook cannot see a shared mailbox calendar managed for director.

Likely cause ranking (most probable first):
1. Permissions/access boundary
2. License/client prerequisite issue
3. Sensitivity label restriction
4. Data indexing lag
5. Guest/external sharing limitation
6. Genuine Copilot fault

Fastest check:
- Confirm delegate permissions and whether the shared mailbox calendar is accessible under the assistant's effective identity for Copilot scenarios.

Is this actually a Copilot bug?
- No. Shared mailbox and delegate access patterns are commonly constrained by access-boundary behavior rather than Copilot defects.

## Quick Triage Pattern Summary
- If the issue is one user and one file: check permissions/labels first.
- If the issue is new user or new content: check indexing lag first.
- If the issue is external or guest-shared content: check guest/external limitation first.
- If the issue is whole team suddenly: check license/client prerequisites first.
- Escalate as genuine Copilot fault only after all above are ruled out.
