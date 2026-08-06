# Structured Triage Summary

## Summary (one line)
VPN connects successfully, but no internal resources are reachable after a Windows 11 upgrade.

## Impact (who/how many/business urgency)
- Who: One end user using VPN after a Windows 11 upgrade (to-verify).
- How many: Single reported user/device so far (to-verify).
- Business urgency: High for that user because remote access to internal services is unavailable despite VPN connection (to-verify).

## Known facts
- Ticket reference is T-1008.
- VPN connection succeeds.
- Internal resources are not reachable.
- The issue is reported after a Windows 11 upgrade.

## Missing information to gather
- Which internal resources fail: file shares, intranet, remote desktop, line-of-business apps, or all of them.
- Whether DNS names fail, direct IP access fails, or both (to-verify).
- Whether the user is on home network, mobile hotspot, or another remote connection.
- Whether the issue started immediately after the upgrade.
- Whether other users on the same VPN service are affected.
- Whether the user can reach any corporate service at all while connected.
- Exact VPN client used and whether the client itself was updated during the upgrade process.

## Likely category
Post-upgrade VPN routing, DNS, or remote access path issue on Windows 11.

## First diagnostic step
Confirm whether the failure is name resolution, routing, or broader access by testing one known internal resource by hostname and by IP while connected to VPN; this quickly narrows the issue to DNS/pathing versus full remote access failure.