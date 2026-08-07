Symptom: Users see a black screen after AVD login on the Finance host pool; for some users it clears after about 30 seconds, while for others it persists.

Cause: Graphics driver regression introduced by the 02:00 overnight image update to POOL-FIN-01.

Scope: Impact was limited to POOL-FIN-01, affecting about 40% of Finance users. POOL-FIN-02 (IT pool) was unaffected because it was not included in that update wave.

Workaround: Move affected users to the healthy pool to restore access while the affected image path is corrected.

Permanent fix: Apply the image-focused corrective change (rollback/patch path) for POOL-FIN-01 and re-test before wider redeploy.

How to spot it: Black screen appears immediately post-login in POOL-FIN-01 after an image update window, with partial pool impact and a clear pool split (POOL-FIN-02 unaffected). In this RCA set, no event IDs, specific error strings, or module names were recorded.