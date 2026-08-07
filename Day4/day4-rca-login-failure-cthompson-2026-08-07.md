# RCA: Single-User Login Failure (cthompson)

## 1) Incident Summary
- Incident type: User login failure
- Affected user: FINBRIDGE\cthompson
- Affected endpoint: DESKTOP-FB022
- Start time observed: ~08:40
- Resolution time: 09:09 AM
- User impact: cthompson unable to log in until account recovery sequence was applied

## 2) Scope and Impact
- Scope: One user only (cthompson)
- Breadth: No evidence of multi-user or platform-wide impact in provided dataset
- Status at closure: User successfully logged in; no further issues reported

## 3) Supporting Evidence

### Authentication Failures and Lockout Sequence
- 08:44:01 - Security Event 4776 Audit Failure
  - Account: FINBRIDGE\cthompson
  - Error: 0xC000006A (wrong password)
  - Source workstation: DESKTOP-FB022

- 08:44:03 - Security Event 4625 Audit Failure
  - Account: FINBRIDGE\cthompson
  - Failure reason: Unknown user name or bad password
  - Logon type: 2 (Interactive)
  - Source: DESKTOP-FB022

- 08:44:28 - Security Event 4625 Audit Failure
  - Account: FINBRIDGE\cthompson
  - Failure reason: Unknown user name or bad password
  - Logon type: 2 (Interactive)
  - Source: DESKTOP-FB022

- 08:44:55 - Security Event 4625 Audit Failure
  - Account: FINBRIDGE\cthompson
  - Failure reason: Unknown user name or bad password
  - Logon type: 2 (Interactive)
  - Source: DESKTOP-FB022

- 08:44:56 - Security Event 4740 Audit Failure
  - Account: FINBRIDGE\cthompson
  - Event: Account locked out
  - Caller computer: DESKTOP-FB022

- 08:45:10 - Security Event 4625 Audit Failure
  - Account: FINBRIDGE\cthompson
  - Failure reason: Account locked out
  - Logon type: 7 (Unlock attempt)
  - Source: DESKTOP-FB022

### Additional Wrong-Password Attempts (Second Source)
- 08:45:44 - Security Event 4771 Audit Failure
  - Account: FINBRIDGE\cthompson
  - Failure code: 0x18 (wrong password)
  - Source IP: 10.10.8.112

- 08:46:01 - Security Event 4771 Audit Failure
  - Account: FINBRIDGE\cthompson
  - Failure code: 0x18 (wrong password)
  - Source IP: 10.10.8.112

- 08:46:33 - Security Event 4771 Audit Failure
  - Account: FINBRIDGE\cthompson
  - Failure code: 0x18 (wrong password)
  - Source IP: 10.10.8.112

### Recovery and Success Confirmation
- 09:08:14 - Security Event 4722 Audit Success
  - Event: User account enabled
  - Account: FINBRIDGE\cthompson
  - Done by: FINBRIDGE\helpdesk-admin

- 09:09:01 - Security Event 4624 Audit Success
  - Event: Successful logon
  - Account: FINBRIDGE\cthompson
  - Logon type: 2 (Interactive)
  - Source: DESKTOP-FB022

## 4) Timeline
- ~08:40: User unable to log in (incident start window)
- 08:44:01 to 08:44:55: Repeated wrong-password failures recorded
- 08:44:56: Account lockout recorded (Event 4740)
- 08:45:10: Locked-out login attempt recorded
- 08:45:44 to 08:46:33: Continued wrong-password Kerberos pre-auth failures from source 10.10.8.112
- 09:08:14: Account enabled by helpdesk-admin (Event 4722)
- 09:09:01: Successful interactive login from DESKTOP-FB022 (Event 4624)
- 09:09 AM: Issue marked resolved; user verified working; no further issue reported

## 5) Root Cause Statement
Primary root cause was account lockout triggered by repeated wrong-password authentication attempts for FINBRIDGE\cthompson. Evidence shows multiple bad-password failures followed by lockout and locked-out attempts, then recovery after account enable and successful interactive sign-in.

## 6) 5-Why Analysis
1. Why could cthompson not log in?
- The account was locked out, then login attempts were denied.

2. Why was the account locked out?
- Multiple wrong-password attempts occurred in a short period.

3. Why were there multiple wrong-password attempts?
- Authentication failures were generated from DESKTOP-FB022 and also from source IP 10.10.8.112 using wrong credentials.

4. Why did login succeed after intervention?
- Account recovery action was applied (account enabled), then a successful interactive sign-in occurred.

5. Why did the incident persist until 09:09?
- Lockout condition remained in effect until administrative account recovery and subsequent valid sign-in.

## 7) Resolution Actions Taken
1. Executed account recovery path for FINBRIDGE\cthompson.
2. Account enable action recorded (Event 4722 at 09:08:14 by FINBRIDGE\helpdesk-admin).
3. User performed interactive login on DESKTOP-FB022.
4. Successful sign-in confirmed (Event 4624 at 09:09:01).
5. Verified user access restored and no further issues reported.

## 8) Preventive Actions
1. Identify and remediate the credential retry source at 10.10.8.112 to prevent repeated wrong-password submissions.
2. Add lockout triage checklist item to check for multi-source authentication attempts (workstation plus alternate IP).
3. Require post-recovery monitoring window for repeated 4771/4776/4625 events before final closure.
4. Reinforce user guidance to stop repeated login attempts and contact Service Desk after initial failures.

## 9) Closure Validation
- Technical validation: Event 4624 success at 09:09:01 from DESKTOP-FB022.
- Service validation: User confirmed login restored; no further issues reported at closure.