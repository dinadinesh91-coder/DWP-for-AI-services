# Known Error Record: AVD Black Screen After Login (POOL-FIN-01)

Version header: v 1.0, 07/08/2026, status : Draft

## Summary
Users can authenticate to Azure Virtual Desktop on POOL-FIN-01 but receive a black screen instead of a usable desktop. Some sessions recover after about 30 seconds; others remain unusable until disconnect.

## Scope
- Host pool: POOL-FIN-01
- Control pool: POOL-FIN-02
- User impact: about 40% of Finance users during the affected wave
- Start window: after the 02:00 image update, first broad reporting around 07:00

## Confirmed Cause
- Graphics driver regression introduced by the POOL-FIN-01 overnight image update.

## Detection Markers
- WVDConnections shows the issue is isolated to POOL-FIN-01.
- WVDErrors may show session retries on POOL-FIN-01 but not POOL-FIN-02.
- TerminalServices-LocalSessionManager Operational shows Event IDs 21 and 22 for the affected login, proving authentication and shell handoff occurred.
- Event ID 24 may appear when the unusable session is disconnected.
- Windows System log may show Event ID 4101 from Display near the failed login timestamp.
- VMSS imageReference.id on POOL-FIN-01 differs from the healthy POOL-FIN-02 image state.

## Workaround
- Drain affected POOL-FIN-01 hosts.
- Route affected users to the POOL-FIN-02 desktop application group.

## Permanent Fix
- Repoint the POOL-FIN-01 VMSS model to the last known-good image and validate on one canary instance before full rollout.

## Validation
- Successful new sessions return on POOL-FIN-01.
- POOL-FIN-02 fallback usage drops back to normal.
- No new Event ID 4101 entries appear during the validation sign-in.

## Related
- kb-l2-l3-avd-black-screen-pool-fin-01.md
- runbook-avd-black-screen-pool-fin-01.md