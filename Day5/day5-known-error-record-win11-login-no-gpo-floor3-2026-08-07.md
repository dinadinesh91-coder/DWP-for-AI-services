Symptom : Users on affected Floor 3 Windows 11 endpoints experience login failure or delayed/unreliable domain sign-in. Startup domain policy processing fails on those devices.

Cause : The verified root cause is a Floor 3 DHCP scope misconfiguration after DNS migration, where Option 006 still referenced decommissioned DNS servers. This prevented domain controller name resolution and led to secure channel and Group Policy processing failures.

Scope : Three Windows 11 machines on Floor 3 were affected (example affected host: DESKTOP-FB031). Comparison hosts with correct DNS assignment, including DESKTOP-FB029 and FB058, were unaffected.

Workaround : Restore service by updating Floor 3 DHCP Option 006 to active DNS servers (primary 10.10.0.10), then renew client lease and refresh DNS state on impacted endpoints. This allows DC discovery and policy processing to recover.

Permanent fix: Keep Floor 3 DHCP scope DNS settings corrected to active resolvers and validate policy processing after change. Enforce mandatory DHCP Option 006/015 pre/post migration validation with subnet/floor sign-off and automated stale-DNS scope detection.

How to spot it: Look for Netlogon Event 5719 (no domain controller available), DNS Client Event 1014 (FINBRIDGE-DC01.finbridge.local resolution timeout), GroupPolicy Events 1058/1030/1129 (SYSVOL/GPO processing failure), and DHCP Client Event 50036 showing old DNS assignment on affected hosts. In this incident window on DESKTOP-FB031: 5719 at 07:40:08, 1058 at 07:40:09 and 07:40:11, 1030 at 07:40:10, 1129 at 07:40:12 and 07:44:01, 1014 at 07:41:05, and 50036 at 07:42:18.
