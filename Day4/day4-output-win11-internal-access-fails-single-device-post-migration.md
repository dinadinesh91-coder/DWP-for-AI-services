Ranked likely causes (most probable first):

1. VPN or Always On VPN profile not connected or not applying correctly (to confirm)
Why it fits: Public internet works but private resources fail, and only one migrated device is affected. That pattern strongly matches missing private-route access on that endpoint rather than a site-wide outage.
Fastest check: Verify VPN status in Windows Settings and confirm a corporate VPN tunnel is active.

2. Device not fully compliant/registered, so conditional access blocks internal resources (to confirm)
Why it fits: Post-migration, one device can lose compliant state while others remain healthy. Internet still works, but SharePoint/internal access can be denied per-device.
Fastest check: In Company Portal (or Access work or school), check the device compliance/sync state.

3. DNS suffix or corporate DNS resolution missing on this device (to confirm)
Why it fits: Internet domains resolve, but internal names for SharePoint/files may not. Single-device impact after migration is consistent with local DNS client configuration drift.
Fastest check: Run nslookup for an internal host and confirm it resolves via corporate DNS servers.

4. Stale credentials/tokens after profile migration causing auth failure to Microsoft 365 and file services (to confirm)
Why it fits: Migration can leave broken cached auth on one user profile. User can browse internet, but access to protected internal resources fails.
Fastest check: Attempt SharePoint in an InPrivate browser session and observe whether sign-in succeeds.

5. Mapped drives point to legacy path or are not remapped under the new profile context (to confirm)
Why it fits: One-device, post-migration failures often come from user-profile remapping issues. SharePoint and mapped drives failing together can reflect outdated path/auth context.
Fastest check: Check one failed mapped drive path and test the same UNC path directly in File Explorer.
