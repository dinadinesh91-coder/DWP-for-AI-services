# Day 5 RCA: Win11 Login Failure / No Group Policy on Floor 3

Date written: 2026-08-07  
Incident date/time window: 2024-03-15 07:40-07:55  
Prepared by: DWP Engineering

## 1. Executive Summary
Three Windows 11 endpoints on Floor 3 failed domain policy processing during startup and presented login failure symptoms. The issue was caused by stale DNS server values in the Floor 3 DHCP scope, which pointed clients to decommissioned DNS infrastructure after migration. This prevented domain controller name resolution, broke secure channel establishment during startup, and caused Group Policy processing failures.

Corrective action was applied by updating DHCP scope DNS settings to active resolvers and renewing affected clients. Post-change validation confirmed successful logon and stable policy processing. User verified login to host and reported no further issues.

## 2. Incident Scope and Impact
- Affected population: 3 Win11 machines on Floor 3 (example affected host: DESKTOP-FB031).
- Unaffected comparison host: DESKTOP-FB029 (same OU, correct DNS assignment).
- User impact:
  - Login failures or delayed/unreliable domain sign-in experience.
  - Domain policy processing failures at startup.
- Business impact:
  - Reduced endpoint availability for affected users.
  - Service desk and engineering effort required for triage/remediation.

## 3. Supporting Evidence
### A. Affected host event evidence (DESKTOP-FB031)
- 07:40:08, Netlogon Event 5719 (Error): unable to set up secure channel; no domain controller available; DNS query for FINBRIDGE-DC01.finbridge.local returned no response.
- 07:40:09, GroupPolicy Event 1058 (Error): failed to access \\FINBRIDGE-DC01\sysvol\finbridge.local\Policies\...\gpt.ini; error 0x3.
- 07:40:10, GroupPolicy Event 1030 (Warning): cannot query list of Group Policy objects; error 0x546.
- 07:40:12, GroupPolicy Event 1129 (Error): Group Policy failed due to no network connectivity to a domain controller.
- 07:41:05, DNS Client Event 1014 (Warning): resolution timeout for FINBRIDGE-DC01.finbridge.local; configured DNS servers did not respond.
- 07:42:18, DHCP Client Event 50036 (Information): lease assigned with old DNS server value (decommissioned).
- 07:44:01, GroupPolicy Event 1129 (Error): repeated no-DC connectivity during policy processing.

### B. Comparison evidence from unaffected host (DESKTOP-FB029)
- 07:40:05, DHCP Client Event 50036: DNS assigned as 10.10.0.10 (active/correct).
- 07:40:11, GroupPolicy Event 1500 (Information): Group Policy settings processed successfully.

### C. DHCP/server-side comparison evidence
- Affected group (FB055-FB057): received decommissioned Floor 3 DNS value.
- Unaffected machine (FB058): DNS set to 10.10.0.10 (manually preconfigured), remained healthy.
- Observed mismatch confirms configuration divergence at DHCP scope level for Floor 3 subnet.

## 4. Incident Timeline (Detailed)
1. 07:40:02 - NLA service running state reported (Service Control Manager 7036).
2. 07:40:08 - Netlogon 5719: secure channel setup failed because no DC was reachable through DNS.
3. 07:40:09 - GP 1058: SYSVOL path inaccessible.
4. 07:40:10 - GP 1030: GPO enumeration failed.
5. 07:40:12 - GP 1129: explicit no domain controller connectivity.
6. 07:41:05 - DNS Client 1014: DC FQDN resolution timed out.
7. 07:42:18 - DHCP 50036: client received stale/decommissioned DNS value.
8. 07:44:01 - GP 1129 repeated, confirming persistent dependency failure.
9. Post-triage - DHCP scope Option 006 corrected to active DNS (10.10.0.10 primary).
10. Post-fix - Affected endpoints renewed lease and DNS cache/registration refreshed.
11. Post-fix verification - DC discovery and Group Policy processing succeeded; user login confirmed working.

## 5. 5 Whys Analysis
1. Why did users experience login/policy failures on Floor 3 machines?
Because endpoints could not contact a domain controller during startup policy processing.

2. Why could endpoints not contact a domain controller?
Because DC hostname resolution failed and SYSVOL path lookup failed.

3. Why did DC hostname resolution fail?
Because DHCP assigned decommissioned DNS server IP addresses to Floor 3 clients.

4. Why was DHCP assigning decommissioned DNS values?
Because the Floor 3 DHCP scope Option 006 was not updated during/after DNS migration cutover.

5. Why was the scope update missed?
Because migration execution controls/checklists did not enforce a subnet-level DHCP option validation gate and post-cutover verification for each floor/VLAN.

## 6. Root Cause Statement
Primary root cause: Floor 3 DHCP scope misconfiguration (stale Option 006 DNS servers) after DNS migration cutover.  
Technical effect: clients queried decommissioned resolvers, failed domain controller resolution, and then failed secure channel and Group Policy processing during startup/logon.

## 7. Resolution Implemented
1. Updated Floor 3 DHCP scope Option 006 to active DNS servers, with 10.10.0.10 as primary.
2. Renewed DHCP lease and refreshed DNS state on impacted endpoints.
3. Validated DC resolution and discovery from impacted machines.
4. Re-ran Group Policy processing and confirmed successful completion.

## 8. Validation of Recovery
- User validation: successful login to host; no further issues reported.
- Technical validation expectations met:
  - No recurring Netlogon 5719 for incident pattern.
  - No recurring DNS Client 1014 for DC FQDN.
  - No recurring GroupPolicy 1058/1030/1129 sequence.
  - Successful policy processing observed (including comparison baseline behavior).

## 9. Preventive and Corrective Actions
### Immediate preventive actions
1. Add mandatory DHCP Option 006/015 verification to every DNS migration runbook.
2. Add pre-cutover and post-cutover sign-off for every subnet/floor scope.
3. Add automated scan to detect decommissioned DNS IPs in all DHCP scopes.

### Operational hardening
1. Implement floor/VLAN canary tests after network or DNS changes:
- DC FQDN resolution
- SYSVOL access
- gpupdate success
2. Require explicit rollback criteria and escalation trigger when canary fails.
3. Store this pattern as a known error with rapid triage checklist.

### Governance improvements
1. Add change template field requiring evidence of DHCP scope audit completion.
2. Introduce peer review checkpoint for DHCP changes tied to migrations.
3. Track closure evidence in post-implementation review artifacts.

## 10. Lessons Learned
- Same-OU affected/unaffected comparison is high-value for quickly eliminating AD OU and GPO filtering hypotheses.
- Event sequencing across Netlogon, DNS Client, and GroupPolicy logs provides strong causal direction for domain dependency failures.
- DHCP/DNS migration tasks must be validated per subnet to avoid floor-isolated incidents.

## 11. Closure Status
Closed: resolution applied and verified.  
User confirmation: successful login and no ongoing issue reported.
