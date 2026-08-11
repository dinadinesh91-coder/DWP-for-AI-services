# Day 5 Solution: Win11 Login Failure / No Group Policy (Floor 3)

Date: 2026-08-07  
Owner: DWP Engineering  
Incident Pattern: Floor 3 endpoints failing login-time domain policy processing due to DNS/DC discovery failure.

## Confirmed Surviving Cause
DHCP scope for the Floor 3 subnet was still assigning decommissioned DNS server IPs, causing domain controller name resolution failure and downstream Group Policy/login issues.

## Resolution Steps

1. Correct DHCP DNS settings for Floor 3 scope
- Open DHCP on the authoritative server.
- Locate the Floor 3 subnet scope used by affected clients.
- Edit Scope Option 006 (DNS Servers):
  - Remove decommissioned DNS IPs (for example `10.10.3.250` and `172.16.5.5` if present).
  - Add active DNS server(s), with primary `10.10.0.10`.
- If DHCP failover is configured, confirm partner sync is healthy.

2. Refresh leases and DNS client state on affected endpoints
- Run elevated commands on each impacted machine:

```powershell
ipconfig /release
ipconfig /renew
ipconfig /flushdns
ipconfig /registerdns
```

3. Verify corrected DNS assignment
- Confirm DNS servers are now correct:

```powershell
ipconfig /all
```

- Expected: DNS server list includes active resolver(s), primary `10.10.0.10`.

4. Validate DC discovery and name resolution
- Run on each impacted endpoint:

```powershell
nslookup FINBRIDGE-DC01.finbridge.local
nltest /dsgetdc:finbridge.local
```

- Expected:
  - `nslookup` returns valid A record quickly.
  - `nltest` returns a reachable domain controller.

5. Reprocess Group Policy and confirm recovery
- Force GP refresh:

```powershell
gpupdate /force
```

- Verify applied computer policy:

```powershell
gpresult /r /scope computer
```

- Event log validation (post-fix):
  - No new Netlogon Event `5719`
  - No new DNS Client Event `1014` for DC names
  - No new GroupPolicy Events `1058`, `1030`, `1129`
  - Presence of successful GP processing events (for example `1500`)

6. Validate secure channel only for residual outliers
- If any one endpoint still fails after DNS correction:

```powershell
Test-ComputerSecureChannel -Verbose
```

- If test returns false, repair:

```powershell
Test-ComputerSecureChannel -Repair -Credential <domain\admin>
```

## Success Criteria
- Affected users can sign in without domain policy errors.
- `gpupdate /force` completes successfully on remediated endpoints.
- DC discovery and SYSVOL access are stable.
- Incident pattern no longer isolated to Floor 3.

## Prevention Actions
- Add DHCP Option 006/015 validation to migration runbook pre/post checks.
- Add alerting for scopes still pointing at decommissioned DNS servers.
- Add per-floor/VLAN canary checks after network/DNS change windows:
  - DC FQDN resolution
  - `\\<domain>\SYSVOL` accessibility
  - `gpupdate /force` success
- Record this as a known-error pattern for rapid triage.
