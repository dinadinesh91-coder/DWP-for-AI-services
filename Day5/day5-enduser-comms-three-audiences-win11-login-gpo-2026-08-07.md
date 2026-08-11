# Day 5 Communications Pack: Win11 Login / Group Policy Incident

## Audience 1 - Non-technical executive
Your access is restored, and your data is safe. On Floor 3, three Windows 11 devices could not sign in correctly because a local network setting still pointed to an old address after a migration. We corrected that setting, refreshed the affected devices, and confirmed normal sign-in and policy updates. You do not need to do anything unless you notice a new sign-in issue; if you do, contact the Service Desk.

## Audience 2 - Affected end-user team (10 people, non-technical)
Access is now restored and your data is safe. Three Floor 3 Windows 11 computers had sign-in problems because they were still using an old network address after a planned migration. We updated the setting, refreshed those devices, and verified normal sign-in and updates. If you see the same issue again, restart once and try sign-in again. If it continues, contact the Service Desk and mention the Floor 3 login incident.
Access is now restored and your data is safe. Three Floor 3 Windows 11 computers had sign-in problems because they were still using an old network address after a planned migration. We updated the setting, refreshed those devices, and verified normal sign-in and updates. If you see the same issue again, contact the Service Desk and mention the Floor 3 login incident.

## Audience 3 - Engineer-to-engineer internal note
Incident: Floor 3 Win11 login/GPO processing failure (3 endpoints affected).

Root cause:
- Floor 3 DHCP scope misconfiguration after DNS migration: Option 006 still referenced decommissioned DNS resolver(s), causing DC name resolution failure.
- Effect chain: DNS resolution timeout -> Netlogon secure channel failure -> SYSVOL/GPO processing failures at startup/logon.

Supporting evidence:
- Affected host (FB031):
  - 07:40:08 Netlogon 5719: no DC available; DNS query for FINBRIDGE-DC01 no response.
  - 07:40:09 GroupPolicy 1058: cannot access \\FINBRIDGE-DC01\sysvol\...\gpt.ini (0x3).
  - 07:40:10 GroupPolicy 1030: cannot query GPO list (0x546).
  - 07:40:12 and 07:44:01 GroupPolicy 1129: no DC connectivity.
  - 07:41:05 DNS Client 1014: FINBRIDGE-DC01 resolution timeout.
  - 07:42:18 DHCP Client 50036: stale/decommissioned DNS assigned.
- Unaffected comparison (FB029, same OU):
  - 07:40:05 DHCP 50036: DNS 10.10.0.10 (correct).
  - 07:40:11 GroupPolicy 1500: GP processed successfully.

Exact action taken:
1. Updated Floor 3 DHCP scope Option 006:
- Removed decommissioned DNS entries.
- Set active DNS server(s), primary 10.10.0.10.
2. Refreshed affected endpoints:
- ipconfig /release
- ipconfig /renew
- ipconfig /flushdns
- ipconfig /registerdns
3. Revalidated policy pathing:
- nslookup FINBRIDGE-DC01.finbridge.local
- nltest /dsgetdc:finbridge.local
- gpupdate /force
- gpresult /r /scope computer

Verification outcome:
- User confirmed successful login; no further issue reported.
- No recurrence of 5719/1014/1058/1030/1129 incident pattern post-fix.
- Policy processing restored.

Preventive action required:
1. Make DHCP Option 006/015 validation mandatory in DNS migration pre/post checklists (per subnet/floor).
2. Add automated detection for decommissioned DNS IPs in DHCP scopes.
3. Run post-change canary checks per floor/VLAN:
- DC FQDN resolution
- SYSVOL access
- gpupdate success
