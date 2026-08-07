# Prompt

Based on the incident analysis and RCA document, write end-user communication for three audiences. Each version must carry exactly the same facts, with audience-appropriate language.

# Output

## Audience 1 — Non-technical executive
Your access and data are safe. This morning, about 40% of Finance virtual desktop users saw a black screen after sign-in; for some it cleared after about 30 seconds. It began after an overnight software update to the Finance group only; the IT group was unaffected. We moved affected users to the healthy group and corrected that update with re-testing before wider release. You do not need to do anything.

## Audience 2 — Affected end-user team (10 people, non-technical)
Hi team, your access and data are safe. This morning, around 40% of users in the Finance virtual desktop group saw a black screen after sign-in (it cleared after about 30 seconds for some users) because an overnight software update to that group introduced an issue, while the IT group was unaffected because it was not updated. We moved affected users to the healthy group and corrected the update with re-testing before wider release. If you see this again, contact the Service Desk at ext 4421.

## Audience 3 — Engineer-to-engineer internal note
Root cause: graphics driver regression in POOL-FIN-01 host image introduced in 02:00 overnight image update.
Config/scope detail: ~40% impact in POOL-FIN-01; symptom black screen post-login, clears ~30s for some and persists for others; POOL-FIN-02 not updated and unaffected.
Action taken: affected users moved to healthy pool; image corrected via rollback/patch path.
Verification step: re-test completed prior to wider redeploy.
Preventive action: enforce pre-release image validation and pilot-ring gating before full pool rollout.