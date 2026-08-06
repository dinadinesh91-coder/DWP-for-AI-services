# Structured Triage Summary

## Summary (one line)
User cannot connect to VDI today from home Wi-Fi; access worked on Friday.

## Impact (who/how many/business urgency)
- Who: One end user reporting inability to access VDI (to confirm).
- How many: Single reported user so far; no broader outage confirmed (to confirm).
- Business urgency: User currently blocked from VDI-based work; priority level not stated (to confirm).

## Known facts
- Issue is occurring today.
- Error shown is "cannot connect" when trying to access VDI.
- VDI access reportedly worked on Friday.
- User is working from home on Wi-Fi.

## Missing information to gather
- Exact VDI platform and connection method used (client app, web portal, VPN path).
- Full error wording/code and at which step it appears.
- Whether VPN is connected and stable.
- Whether user can reach other corporate services from home network.
- Whether issue reproduces after rebooting device and router.
- Whether other users are also unable to connect to VDI.
- Device details (managed laptop vs personal device, OS version, recent updates).
- Time issue started and whether it is constant or intermittent.

## Likely category
Remote access/VDI connectivity issue, potentially home network path or VPN/auth/session problem (to confirm).

## Suggest first diagnostic step
Confirm whether VPN is connected and then retry VDI while capturing the exact error message/code; this quickly separates local network/VPN prerequisites from VDI platform-side issues.
