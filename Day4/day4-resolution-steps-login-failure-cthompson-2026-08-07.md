# Day4 Resolution Record: Login Failure (cthompson)

## Surviving Hypothesis
Account lockout driven by repeated wrong-password attempts for cthompson, with retries from both DESKTOP-FB022 and a second source at 10.10.8.112, causing lockout and continued failed logons.

## Detailed Resolution Steps

1. Freeze further bad attempts before recovery.
- Instruct the user to stop sign-in attempts.
- End active sign-in retries from DESKTOP-FB022.
- Identify and stop authentication retries from 10.10.8.112.

2. Confirm lockout state in identity logs.
- Validate wrong-password failures, then lockout, then locked-out attempts in sequence.

3. Unlock only after retry sources are stopped.
- Unlock cthompson only when no active bad-attempt source remains.

4. Reset credentials in a controlled order.
- Reset password for cthompson.
- Communicate exact next-login sequence to the user.

5. Remove stale cached credentials on both sources.
- Clear stored credentials/tokens on DESKTOP-FB022.
- Clear stored credentials/tokens on the system at 10.10.8.112.

6. Test clean sign-in path.
- Perform one interactive sign-in test for cthompson on DESKTOP-FB022.

7. Verify recovery in logs.
- Confirm successful sign-in and absence of new 4776/4625/4740/4771 failures during the validation window.

8. Close after short stability monitoring.
- Keep incident in monitor state briefly and close only if no recurrence is observed.