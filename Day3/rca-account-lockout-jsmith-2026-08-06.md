# RCA: User Lockout Incident (jsmith)

Date of analysis: 2026-08-06  
Incident window reviewed: 08:02 to 08:23 (approx. 30 minutes)  
System: DESKTOP-FB001  
User account: jsmith

## 1) Event ID Meaning (What each event records)

### Event ID 4625 (Audit Failure) - Failed logon attempt
Records a failed authentication attempt.
- In this incident, two early 4625 events show reason: "Unknown username or bad password" with logon type 2 (Interactive), meaning someone at the local sign-in screen (or equivalent local interactive context) entered invalid credentials.
- A later 4625 shows reason: "Account locked out" with logon type 7 (Unlock), meaning a failed attempt to unlock an already locked workstation/session because the account was locked.

### Event ID 4740 (Audit Failure category in source text; functionally account lockout event) - Account locked out
Records that the account lockout threshold was reached and the account was locked.
- Includes caller/source machine: DESKTOP-FB001.
- This is the key control event confirming when lockout happened.

### Event ID 4722 (Audit Success) - User account enabled
Records that an account was enabled by an administrator or delegated operator.
- Here, action was performed by FINBRIDGE\helpdesk-admin.
- This indicates administrative intervention to restore account usability.

### Event ID 4624 (Audit Success) - Successful logon
Records successful authentication.
- In this incident, logon type 2 (Interactive), confirming jsmith successfully logged on locally after administrative recovery.

## 2) Reconstructed Sequence in Plain English

1. At 08:02:14, jsmith (or someone at DESKTOP-FB001) attempted an interactive sign-in with an invalid password.
2. At 08:04:22, another invalid interactive sign-in occurred for jsmith from the same machine.
3. At 08:06:01, the account hit lockout policy threshold and was locked (Event 4740), with caller identified as DESKTOP-FB001.
4. At 08:07:45, there was an unlock attempt (logon type 7), but it failed because the account was already locked.
5. At 08:22:10, helpdesk-admin enabled/unlocked the account (Event 4722).
6. At 08:23:44, jsmith successfully signed in interactively (Event 4624), showing service restoration.

## 3) Most Likely Cause of Lockout (with evidence)

Most likely cause: repeated bad password entries at the local interactive logon screen on DESKTOP-FB001 caused the account to hit lockout threshold.

Evidence from events:
- Two consecutive failed interactive logons for jsmith with "Unknown username or bad password" (4625 at 08:02:14 and 08:04:22; logon type 2).
- Direct lockout event for jsmith called from DESKTOP-FB001 (4740 at 08:06:01).
- Subsequent failure reason changed to "Account locked out" during unlock attempt (4625 logon type 7 at 08:07:45), confirming lockout state.
- Administrative action followed by successful sign-in (4722 then 4624), consistent with lockout remediation.

Assessment confidence: High.

## 4) Detailed RCA

### Incident Summary
User jsmith was locked out during normal endpoint access on DESKTOP-FB001 after multiple bad-password attempts. The account was restored by helpdesk, and the user then logged in successfully.

### Impact
- User could not access workstation during lockout period.
- Short-term productivity interruption from approximately 08:06 to 08:23.
- Helpdesk intervention required.

### Detection
- Security log failures (4625) and lockout event (4740) indicate threshold breach.
- User-facing symptom: inability to sign in/unlock due to lockout.

### Contributing Factors
- Credential mismatch at interactive sign-in.
- Account lockout policy enforcement (working as designed).
- No evidence in provided window of remote/service-origin attempts; all evidence points to local endpoint DESKTOP-FB001.

### Containment and Recovery
- Helpdesk-admin re-enabled account at 08:22:10 (4722).
- User successfully logged in at 08:23:44 (4624).

## 5) Five Whys Analysis

1. Why was jsmith locked out?
Because the account exceeded failed sign-in threshold and was locked by policy (4740 at 08:06:01).

2. Why was the failed sign-in threshold exceeded?
Because there were repeated failed interactive logon attempts with bad credentials (4625 at 08:02:14 and 08:04:22).

3. Why were bad credentials repeatedly submitted?
Most likely the user entered an incorrect password multiple times at the local sign-in screen (logon type 2 on same endpoint).

4. Why did the user continue to fail after lockout?
An unlock attempt occurred while account was already in locked state (4625 logon type 7, reason "Account locked out"), indicating the user likely did not realize/confirm lockout status before retrying.

5. Why did this require helpdesk intervention?
Because lockout policy requires administrative reset/unlock path in this environment, which was performed by FINBRIDGE\helpdesk-admin (4722).

Root cause statement:
Primary root cause is repeated entry of incorrect credentials for account jsmith at DESKTOP-FB001, triggering configured account lockout policy.

## 6) Corrective and Preventive Actions

### Immediate corrective actions
- Confirmed account restored (4722) and user access validated (4624).
- Advised user to verify current password and keyboard layout/caps-lock state before retries.

### Preventive actions
- User guidance: single retry rule before contacting support to avoid threshold breach.
- Add lockout self-service guidance in login support KB (what to do after first or second failure).
- Review whether current lockout threshold and duration are balanced for security vs. usability.
- Monitor for repeated 4625 patterns on DESKTOP-FB001 for the same account to catch recurring credential-entry issues.

## 7) Validation Checklist for Closure

- [x] 4740 lockout event identified with source host.
- [x] Preceding 4625 bad-password events correlated.
- [x] Post-recovery 4722 administrative enable/unlock confirmed.
- [x] Successful 4624 interactive logon confirmed.
- [ ] Optional: Correlate with user statement (typo/caps-lock/keyboard layout) for final narrative completeness.

## 8) Notes on Scope

This RCA is based only on the provided 30-minute event snippet. No additional domain controller logs, workstation forensic artifacts, cached-credential telemetry, or policy object settings were included in this dataset.
