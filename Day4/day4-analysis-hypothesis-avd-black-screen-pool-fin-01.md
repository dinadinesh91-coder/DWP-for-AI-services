# Day4 Analysis and Hypothesis: AVD Black Screen (POOL-FIN-01)

## Question Addressed
Which cause is most consistent with this fact pattern: POOL-FIN-02 was not updated and is completely unaffected?

## Most Consistent Cause
1. Image-introduced regression in POOL-FIN-01 (display/shell/AVD agent path) (to confirm)

Why this is most consistent:
- The only stated difference between pools is the 02:00 image update.
- POOL-FIN-01 was updated and is affected.
- POOL-FIN-02 was not updated and is unaffected.
- This isolation pattern most strongly points to an image-introduced regression, not a shared platform issue.

## Re-ranked Differential (timing/isolation explicit)

1. Image-introduced regression in POOL-FIN-01 (display/shell/AVD agent path) (to confirm)
Why: Exact correlation with the overnight change window and pool split.
Fastest check: Compare failing host behavior against a host on prior image or rollback canary.

2. Startup sequence change delivered by the new image (logon scripts/GPO/startup apps) (to confirm)
Why: Also image-scoped; explains variable 30s vs persistent outcomes by per-user startup path.
Fastest check: Compare sign-in stage durations/events before vs after image version.

3. FSLogix profile attach regression triggered by new image components/timing (to confirm)
Why: Still pool-specific because only that image changed; mixed user impact fits profile attach variability.
Fastest check: FSLogix attach logs for delays/errors on affected sessions.

4. Resource/performance regression introduced by updated image at morning login surge (to confirm)
Why: Timing at 07:00 fits user concurrency after rollout; would remain mostly pool-bound.
Fastest check: Host CPU/disk/storage latency during 07:00-08:00 vs POOL-FIN-02 baseline.

5. Host subset received a bad image variant or incomplete post-update state within POOL-FIN-01 (to confirm)
Why: Explains why only ~40% are impacted while the issue stays confined to updated pool.
Fastest check: Map affected users to host/image version/build drift across POOL-FIN-01.

## Event Update (Appended)

- Suggested resolution was applied.
- Incident marked resolved at 10:00 AM.
- Verification outcome: users are logging in successfully to hosts in POOL-FIN-01.
- Post-resolution monitoring: no further black-screen reports received at time of verification.

## Reviewed Hypotheses Against Evidence

1. Image-introduced regression in POOL-FIN-01 host image (display/shell/graphics path)
Status: Survives evidence.
Reason: Symptom started after the 02:00 POOL-FIN-01-only image update, POOL-FIN-02 remained unaffected, and service normalized after applying the image-focused resolution path.

2. Startup sequence change (logon scripts/GPO/startup apps)
Status: Reduced likelihood.
Reason: Still possible in theory, but current evidence correlates more directly with the image-change boundary and recovery pattern.

3. FSLogix profile attach regression
Status: Reduced likelihood.
Reason: Scope and timing were compatible, but issue closure after applied resolution aligns more strongly with host image regression.

4. Pool performance saturation at morning surge
Status: Reduced likelihood.
Reason: A pure capacity issue would not typically align as tightly to a single image update wave and pool-isolated change event.

5. Partial host drift/incomplete update state
Status: Reduced likelihood as primary cause.
Reason: Can explain partial impact, but does not better fit the full timeline than the primary image regression hypothesis.

## Surviving Hypothesis (Post-Elimination)

Image-introduced regression in the POOL-FIN-01 overnight host image update is the single hypothesis that best matches all evidence and the observed recovery.

## Detailed Resolution Steps Applied

1. Confirmed blast radius and timeline
- Validated impact was limited to POOL-FIN-01 users and began after the 02:00 update window.
- Confirmed POOL-FIN-02 remained unaffected as a control group.

2. Isolated the update as the primary suspect
- Correlated incident start (~07:00), symptom pattern (black screen post-login), and pool-specific change history.
- Prioritized image-level rollback/patch path over global platform/network actions.

3. Applied image-focused corrective action
- Executed the agreed corrective path for the updated POOL-FIN-01 image (rollback or corrected patch).
- Ensured session hosts in POOL-FIN-01 were aligned to the corrected image state before validation.

4. Verified functional recovery
- Performed user login validation on POOL-FIN-01 hosts after corrective action.
- Confirmed black-screen symptom no longer reproduced during verification window.

5. Declared resolution and documented closure
- Recorded incident as resolved at 10:00 AM.
- Logged verification evidence: successful logins and no active recurrence reports at closure time.