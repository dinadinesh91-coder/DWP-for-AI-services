# RCA: Account Lockout During Remote Interactive Sign-In

Date of analysis: 2026-08-06  
Incident date/time window: 2024-03-15 14:01 to 14:22  
User account: FINBRIDGE\\bwalker  
Primary client/source: 10.10.5.44

## 1) Event ID Explanations

### Security Event ID 4625 (Audit Failure)
Records a failed logon attempt.

What it records in this case:
- Account attempted: FINBRIDGE\\bwalker
- Failure reason: Unknown username or bad password
- Logon type: 10 (RemoteInteractive)
- Source IP: 10.10.5.44

Interpretation:
- Remote Desktop style sign-in attempts from 10.10.5.44 failed due to invalid credentials.

### Security Event ID 4740 (Audit Failure)
Records that a user account was locked out after lockout threshold criteria were met.

What it records in this case:
- Account: FINBRIDGE\\bwalker
- Caller computer: 10.10.5.44
- Description: A user account was locked out

Interpretation:
- The lockout trigger is directly tied to repeated failed attempts coming from 10.10.5.44.

### System Event ID 131 (RemoteDesktopServices-RdpCoreTS, Info)
Records RDP core transport activity, including accepted inbound TCP connection from a client.

What it records in this case:
- Server accepted new TCP connection from 10.10.5.44:52341

Interpretation:
- Network-level RDP connection succeeded at TCP/session transport level.
- This does not by itself prove credential success; it only confirms connection acceptance.

### Security Event ID 4624 (Audit Success)
Records a successful logon.

What it records in this case:
- Account: FINBRIDGE\\bwalker
- Logon type: 10 (RemoteInteractive)
- Source IP: 10.10.5.44

Interpretation:
- A successful RemoteInteractive authentication from the same source IP occurred after earlier lockout.

## 2) Reconstructed Sequence in Plain English

1. At 14:01:04, a RemoteInteractive sign-in attempt for FINBRIDGE\\bwalker from 10.10.5.44 failed due to bad credentials.
2. At 14:03:18, a second RemoteInteractive attempt from the same IP failed for the same reason.
3. At 14:05:33, a third RemoteInteractive attempt from the same IP failed again.
4. One second later at 14:05:34, the account was locked out (Event 4740), and the caller is explicitly identified as 10.10.5.44.
5. At 14:22:07, the server accepted a new RDP TCP connection from 10.10.5.44 (Event 131).
6. At 14:22:09, a successful RemoteInteractive logon (4624) occurred for FINBRIDGE\\bwalker from 10.10.5.44.

## 3) Most Likely Cause of Lockout (with evidence)

Most likely cause:
Repeated incorrect password submission for FINBRIDGE\\bwalker over RemoteInteractive logon type 10 from client 10.10.5.44 caused account lockout policy threshold to be reached.

Evidence:
- Three consecutive 4625 failures with the same failure reason and same source IP.
- Immediate 4740 lockout event one second after the third failure.
- Caller computer in 4740 matches the source IP in failed attempts (10.10.5.44).
- Later 4624 success from same IP indicates authentication eventually succeeded after lockout condition was resolved.

Confidence:
- High for credential failure-driven lockout from that source.
- Medium for exact human vs cached-client origin (manual typing, stale saved credentials, scheduled task, or mapped session) without additional endpoint logs from 10.10.5.44.

## 4) Detailed RCA

### Incident Summary
FINBRIDGE\\bwalker was locked out after repeated failed RemoteInteractive authentications from 10.10.5.44. After lockout, a later RDP connection and successful logon from the same client indicates credentials or account state were corrected.

### Business/User Impact
- User unable to authenticate remotely during lockout interval.
- Potential interruption to remote support/productivity.
- Security policy enforcement triggered correctly.

### Detection and Evidence Sources
- Security log events: 4625, 4740, 4624.
- System log event: 131 from RdpCoreTS.

### Technical Findings
- All failed attempts are logon type 10 (RemoteInteractive), not local interactive.
- Source consistency: all key events tie to 10.10.5.44.
- Temporal causality is tight: third failed logon followed by lockout at +1 second.
- Successful post-window authentication suggests issue was transient/corrected credentials rather than persistent account disablement.

### Containment and Recovery
- Effective recovery occurred before 14:22:09 as shown by successful 4624.
- Root immediate control: lockout policy prevented continued brute-force-like failures.

### Contributing Factors (Most Plausible)
- Incorrect password entered repeatedly in RDP sign-in workflow.
- Potential stale saved credentials in RDP client on 10.10.5.44.
- Potential background process/service/session reuse attempting old credentials from same source.

## 5) Five Whys Analysis

1. Why was FINBRIDGE\\bwalker locked out?
Because account lockout policy threshold was reached, confirmed by Event 4740 at 14:05:34.

2. Why was the threshold reached?
Because there were repeated failed RemoteInteractive logons (three 4625 events) from 10.10.5.44.

3. Why did RemoteInteractive logons fail repeatedly?
Because the authentication attempts used invalid credentials (failure reason: unknown username or bad password).

4. Why were invalid credentials used multiple times from the same source?
Most likely stale/incorrect credential reuse on client 10.10.5.44 (manual retries or saved credential replay in RDP context).

5. Why did this become an incident instead of a single failure?
Because repeated retries occurred before correction, allowing policy threshold to trigger lockout rather than early intervention after first/second failure.

Root cause statement:
The lockout was caused by repeated bad-credential RemoteInteractive authentication attempts for FINBRIDGE\\bwalker from 10.10.5.44, which triggered domain/local lockout policy enforcement.

## 6) Corrective and Preventive Actions

Immediate corrective actions:
- Confirm account unlocked/reset path and successful login already evidenced by Event 4624.
- Clear saved RDP credentials on client 10.10.5.44 for target host and re-enter validated password.
- Confirm no scheduled tasks/services on 10.10.5.44 are using outdated credentials.

Preventive actions:
- User guidance: stop after 1-2 failures and verify account format, keyboard layout, and password state.
- Enforce credential hygiene: remove stale Credential Manager RDP entries.
- Monitoring rule: alert on repeated 4625 logon type 10 for same account+source within short window.
- Review lockout threshold policy for balance between security and support burden.

## 7) Closure Validation Checklist

- [x] Three failed 4625 events confirmed (same account/source/logon type).
- [x] 4740 lockout confirmed and correlated to same source.
- [x] RDP transport reconnection observed (Event 131).
- [x] Successful 4624 for same account/source observed.
- [ ] Optional: Confirm from 10.10.5.44 whether failures were manual input or cached/scheduled credential use.

## 8) Scope and Assumptions

This RCA is based only on the supplied event lines. Additional corroboration from domain controller security logs, endpoint credential manager, RDP client logs, and scheduled task/service credential bindings on 10.10.5.44 would increase attribution precision.