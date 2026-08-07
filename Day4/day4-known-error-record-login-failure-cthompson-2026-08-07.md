Symptom: User FINBRIDGE\cthompson could not log in on DESKTOP-FB022 starting around 08:40. Login attempts failed until account recovery was completed.

Cause: Verified root cause was account lockout triggered by repeated wrong-password authentication attempts. Evidence includes Event 4776 (0xC000006A), repeated Event 4625 bad-password failures, and Event 4740 account lockout.

Scope: This incident affected one user account (FINBRIDGE\cthompson) and one endpoint path (DESKTOP-FB022) in the provided RCA. No multi-user impact was evidenced in the incident dataset.

Workaround: Apply account recovery and restore user access through Service Desk administration. In this case, account enable was performed (Event 4722), followed by successful interactive login.

Permanent fix: Remove the repeated bad-credential source and enforce post-recovery monitoring before closure. The RCA records a second failure source at IP 10.10.8.112, which must be remediated to prevent recurrence.

How to spot it: Look for the event chain 4776 wrong password, multiple 4625 bad-password attempts, 4740 lockout, and post-lockout 4625 locked-out attempts. Additional signal in this incident was repeated 4771 (0x18 wrong password) from source IP 10.10.8.112, with recovery validated by 4722 and 4624 success.