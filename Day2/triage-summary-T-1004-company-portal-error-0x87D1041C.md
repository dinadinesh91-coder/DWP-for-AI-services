# Structured Triage Summary

## Summary (one line)
Company app fails to install from Company Portal with error 0x87D1041C.

## Impact (who/how many/business urgency)
- Who: One user attempting to install a company app from Company Portal (to-verify).
- How many: Single reported user/device so far (to-verify).
- Business urgency: Medium to high, depending on whether the app is required for the user's role or time-sensitive work (to-verify).

## Known facts
- Ticket reference is T-1004.
- A company app fails to install from Company Portal.
- The reported error is 0x87D1041C.

## Missing information to gather
- Exact app name and version shown in Company Portal.
- Whether the app is marked as required, available, or recently updated (to-verify).
- Whether the device is compliant and successfully checking in to management services.
- Whether other apps install successfully from Company Portal.
- Whether other users are seeing the same failure for the same app.
- Whether the failure happens immediately or after download begins.
- Device OS version and whether there was a recent upgrade, re-enrollment, or policy change (to-verify).
- Exact wording shown alongside the error in Company Portal.

## Likely category
Endpoint application deployment / Company Portal app installation issue.

## First diagnostic step
Confirm whether the issue is isolated to this app by testing another available Company Portal install and checking whether the device is successfully syncing with management services; this quickly separates app-package targeting or deployment issues from broader device management or client-side problems.