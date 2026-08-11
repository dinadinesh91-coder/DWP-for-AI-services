# Day 5 Analysis and Hypothesis

Date: 2026-08-07  
Analyst: DWP Engineer  
Scope: Three Windows 11 machines on Floor 3 show login failure symptom context with no Group Policy applying; issue appears floor-specific.

## Constraint
This ranking is based only on the provided scope fact:
- Symptom: no Group Policy for 3rd floor machines only

No single root cause is being declared yet.

## Ranked Top 5 Likely Causes (Most probable first)

### 1) Floor 3 machines are in the wrong AD OU (or moved to a container with no linked GPOs)
Why this fits the scope facts:
- A location-limited pattern (Floor 3 only) strongly matches an OU scoping mistake affecting just those endpoints.
- If machines are in an OU without expected links, GP appears "missing" while other floors remain normal.

Single fastest check:
- In ADUC, verify the exact OU path of all three computer objects and compare with a known-good machine from another floor.

### 2) Security filtering or WMI filtering is excluding only the Floor 3 device set
Why this fits the scope facts:
- GPO can be linked correctly but still not apply if ACL filtering or WMI query excludes a specific hardware/site cohort.
- Floor-based staging groups are commonly used; a misconfigured filter can isolate one floor.

Single fastest check:
- Run `gpresult /r /scope computer` on one affected machine and inspect "Denied GPOs" with reason (Security/WMI filtering).

### 3) Floor 3 machines are authenticating against an unreachable/wrong domain controller path (site/subnet mapping issue)
Why this fits the scope facts:
- Floor-specific network topology can drive DC selection behavior.
- If subnet/site mapping is wrong, devices may target a DC they cannot reliably reach, leading to policy non-processing and login issues.

Single fastest check:
- On an affected machine, run `nltest /dsgetdc:<domain>` and confirm selected DC is reachable and expected for that site.

### 4) Network segmentation or firewall controls on Floor 3 are blocking AD/SYSVOL/LDAP/Kerberos traffic
Why this fits the scope facts:
- A floor-only outage pattern is consistent with VLAN/ACL/firewall differences at that location.
- Group Policy retrieval depends on DC and SYSVOL access; blocked ports can cause "no GP" symptoms and sign-in failures.

Single fastest check:
- From one impacted device, test SYSVOL access with `\\<domain>\SYSVOL`; immediate failure strongly supports network path blocking.

### 5) Machine account trust/channel issue on the three endpoints (common image or provisioning batch problem)
Why this fits the scope facts:
- If all three devices were deployed/rebuilt together, trust channel or computer account drift could be shared.
- Broken secure channel can block normal domain processing, including Group Policy during sign-in.

Single fastest check:
- Run `Test-ComputerSecureChannel -Verbose` in elevated PowerShell on one affected machine.

## Working Hypothesis
The highest-probability cluster is AD scoping/filtering or site/network pathing specific to Floor 3, with OU placement error as the leading candidate. Endpoint trust issues remain plausible but rank lower until directory and network-scoping checks are completed.

## Immediate Triage Order (Fastest elimination path)
1. Verify OU placement of all three devices.
2. Check `gpresult` denied reasons (Security/WMI).
3. Validate DC discovery path (`nltest /dsgetdc`).
4. Test SYSVOL reachability.
5. Check machine secure channel.

## Evidence Assessment Against Each Hypothesis (Incident Log Window)

Source window reviewed:
- Affected example: DESKTOP-FB031, 07:40-07:55
- Unaffected comparison: DESKTOP-FB029 (same OU)

### 1) Wrong AD OU placement / no linked GPOs
Judgement: Contradicts

Why:
- A known-good machine in the same OU processed policy successfully, which argues against OU-link scope as the primary differentiator.

Determining event evidence:
- 07:40:11, GroupPolicy Event 1500 (FB029): "Group Policy settings processed successfully" (same OU as affected set).
- 07:40:08, Netlogon Event 5719 (FB031): no DC available due to DNS no response, indicating connectivity/dependency failure rather than OU link absence.

### 2) Security filtering or WMI filtering exclusion
Judgement: Contradicts

Why:
- The affected path shows DC/DNS reachability failures; filtering issues typically present as denied application while directory/network path remains reachable.
- Same-OU successful application on FB029 reduces likelihood of a broad filter mismatch driving this symptom.

Determining event evidence:
- 07:40:08, Netlogon Event 5719 (FB031): secure channel setup failed, no DC available.
- 07:41:05, DNS Client Event 1014 (FB031): name resolution timeout for FINBRIDGE-DC01; configured DNS did not respond.
- 07:40:11, GroupPolicy Event 1500 (FB029): successful GP processing.

### 3) Wrong/unreachable DC path (site/subnet/DC discovery issue)
Judgement: Supports

Why:
- Events directly indicate inability to locate/reach a DC and repeated policy failures tied to that dependency.

Determining event evidence:
- 07:40:08, Netlogon Event 5719 (FB031): cannot set secure channel, "no domain controller available," DNS query for FINBRIDGE-DC01 no response.
- 07:41:05, DNS Client Event 1014 (FB031): FINBRIDGE-DC01 resolution timed out.
- 07:40:12 and 07:44:01, GroupPolicy Event 1129 (FB031): GP failed due to no network connectivity to a domain controller.

### 4) Floor-specific network segmentation/firewall blocking AD paths
Judgement: Neutral (partial support, not conclusive)

Why:
- There is evidence of failed DC/SYSVOL access, which could result from network controls.
- However, the same log set also points strongly to DNS assignment failure, so firewall/ACL is not uniquely established by these events alone.

Determining event evidence:
- 07:40:09 and 07:40:11, GroupPolicy Event 1058 (FB031): cannot access SYSVOL path (`gpt.ini` path failure).
- 07:40:12, GroupPolicy Event 1129 (FB031): no DC connectivity during GP processing.
- 07:42:18, DHCP Client Event 50036 (FB031): DNS assigned as old/decommissioned resolver, providing an alternate explanation.

### 5) Machine secure channel/account trust issue on endpoints
Judgement: Contradicts

Why:
- The secure-channel error is paired with explicit DNS/DC discovery failure signals, and one peer machine succeeds with correct DNS in same OU context.
- This pattern is more consistent with external dependency failure than per-machine trust corruption.

Determining event evidence:
- 07:40:08, Netlogon Event 5719 (FB031): secure channel setup failed with explicit "no DC available" and DNS no response detail.
- 07:41:05, DNS Client Event 1014 (FB031): DNS timeout for domain controller name.
- 07:40:11, GroupPolicy Event 1500 (FB029): successful GP on comparison machine.

## Status
All five hypotheses have been evaluated against available event evidence without selecting a final winner in this document.

## Addendum: Event Details, Surviving Hypothesis, and Resolution

### Event Detail Summary (Incident Window)
Affected machine profile (DESKTOP-FB031, startup window 07:40-07:55):
- 07:40:08, Netlogon Event 5719 (Error): secure channel setup failed, no domain controller available, DNS query for FINBRIDGE-DC01 had no response.
- 07:40:09, GroupPolicy Event 1058 (Error): cannot access \\FINBRIDGE-DC01\sysvol\...\gpt.ini, error 0x3.
- 07:40:10, GroupPolicy Event 1030 (Warning): cannot query GPO list, error 0x546.
- 07:40:12, GroupPolicy Event 1129 (Error): no network connectivity to a domain controller.
- 07:41:05, DNS Client Event 1014 (Warning): FINBRIDGE-DC01 name resolution timed out; configured DNS did not respond.
- 07:42:18, DHCP Client Event 50036 (Information): DNS assigned as old/decommissioned resolver.
- 07:44:01, GroupPolicy Event 1129 (Error): repeated no-DC connectivity failure.

Comparison profile (DESKTOP-FB029, unaffected, same OU):
- 07:40:05, DHCP Client Event 50036: DNS assigned as 10.10.0.10 (correct).
- 07:40:11, GroupPolicy Event 1500 (Information): Group Policy processed successfully.

DHCP server comparison:
- FB055-FB057 received decommissioned Floor 3 DNS.
- FB058 received 10.10.0.10 (manually preconfigured) and remained unaffected.

### Surviving Hypothesis
Hypothesis 3 survives elimination:
- Floor 3 machines were unable to discover/reach a domain controller because DHCP provided stale DNS resolver settings, causing DC lookup and SYSVOL access failures during startup policy processing.

### Detailed Resolution Steps

1. Correct DHCP Floor 3 scope DNS options
- Open DHCP on the authoritative server.
- Locate the Floor 3 subnet scope used by impacted endpoints.
- Edit Option 006 (DNS Servers): remove decommissioned DNS IPs and set active DNS (primary 10.10.0.10).
- If DHCP failover is enabled, verify partner synchronization.

2. Refresh client lease and DNS state on impacted machines
- Run elevated commands:

```powershell
ipconfig /release
ipconfig /renew
ipconfig /flushdns
ipconfig /registerdns
```

3. Validate corrected DNS assignment
- Run:

```powershell
ipconfig /all
```

- Confirm DNS servers now point to active resolver(s), including 10.10.0.10.

4. Validate DC discovery and resolution
- Run:

```powershell
nslookup FINBRIDGE-DC01.finbridge.local
nltest /dsgetdc:finbridge.local
```

- Expected: name resolution succeeds quickly and nltest returns a reachable DC.

5. Re-run Group Policy and verify recovery
- Run:

```powershell
gpupdate /force
gpresult /r /scope computer
```

- Validate event logs show no new 5719, 1014, 1058, 1030, or 1129 events after remediation and show successful policy processing.

6. Repair secure channel only for residual outliers
- If any endpoint still fails after DNS correction:

```powershell
Test-ComputerSecureChannel -Verbose
```

- If false, run repair:

```powershell
Test-ComputerSecureChannel -Repair -Credential <domain\\admin>
```

7. Hardening and prevention
- Add DHCP Option 006/015 validation to pre/post migration checklists.
- Add monitoring for DHCP scopes referencing decommissioned DNS servers.
- Add per-floor canary checks after DNS/network changes: DC FQDN resolution, SYSVOL access, and policy refresh success.
