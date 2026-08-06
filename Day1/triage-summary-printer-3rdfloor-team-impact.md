# Structured Triage Summary

## Summary (one line)
Shared printer on the 3rd floor is unavailable, affecting the whole team, with a client meeting at 2.

## Impact (who/how many/business urgency)
- Who: Team on/using the 3rd-floor large printer (exact users to confirm).
- How many: "Whole team affected" (exact count to confirm).
- Business urgency: High time sensitivity due to client meeting at 2 (timezone and exact deadline impact to confirm).

## Known facts
- Reported issue: "Printer gone" (meaning unavailable/not visible/not working to confirm).
- Affected device is the "big" printer on the 3rd floor.
- Impact scope reported as whole team.
- There is a client meeting at 2.

## Missing information to gather
- What "gone" means exactly: missing from device list, offline status, paper jam/error, or unable to print.
- Printer asset/queue name and model.
- Exact error messages shown on user devices or print queue.
- Whether printer has power/network link and any panel error on the device.
- Whether any user can print a test page from another floor/device.
- Whether alternative nearby printers are available for immediate workaround.
- Which systems are affected (all PCs, specific VLAN/site, specific app).
- Exact meeting time zone and documents needed before meeting.

## Likely category
Shared network printer outage / print service disruption with multi-user impact (to confirm).

## Suggest first diagnostic step
Confirm physical and network status at source: check the 3rd-floor printer panel for errors and online state, then attempt a test print from the print server/admin queue to quickly determine device-side outage vs client-side mapping issue.
