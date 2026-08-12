# Knowledge Base — L2/L3 Technical Guide
## Autopilot Enrollment Error 0x80180014 — Advanced Troubleshooting & Resolution

**KB ID:** KB-AUTO-L2L3-001  
**Audience:** Intune Admins, Senior Support Engineers, Automation Engineers  
**Last Updated:** 2026-08-11  
**Difficulty Level:** Advanced  

---

## Technical Summary

**Error Code:** `0x80180014`  
**Error Message:** "The device is already enrolled in MDM"  
**Component:** Intune Enrollment Service  
**Root Cause:** Active MDM enrollment exists for device in Intune database when Autopilot re-enrollment is attempted  
**Secondary Error:** `0x80070005` (Access denied on policy delivery due to enrollment context mismatch)  
**Affected Timeframe:** March 2024 Autopilot enrollments (likely migration batch)  

---

## Prerequisites for L2/L3 Troubleshooting

You need:
- Admin access to Intune admin center
- Admin access to Azure AD admin center
- Local admin access to affected device (or remote access via Intune remediation)
- PowerShell 5.0+ on device
- Familiarity with Intune enrollment lifecycle and MDM CSP

---

## Step 1: Verify Issue Diagnosis

### 1.1 Query Intune for Device Record

```powershell
# In Intune admin center PowerShell (Connect-MgGraph required)
$device = Get-MgDevice -Filter "displayName eq 'DESKTOP-FB099'"
$intuneDevice = Invoke-MgGraphRequest -Method GET `
  -Uri "/beta/deviceManagement/managedDevices?`$filter=deviceName eq 'DESKTOP-FB099'"

# Inspect enrollment details
$intuneDevice | Select-Object @(
  'deviceName',
  'enrollmentType',
  'enrollmentDateTime',
  'lastSyncDateTime',
  'managementState',
  'complianceState'
) | Format-Table
```

**Expected findings for this error:**
- `enrollmentType`: "Autopilot" (or possibly null/failed)
- `enrollmentDateTime`: 2024-03-15 or later (enrollment attempt date)
- `lastSyncDateTime`: Much earlier (often 2023-11-04 or similar) — indicates legacy enrollment still cached
- `managementState`: "Managed" or "ManagedButNoncompliant"
- `complianceState`: "NonCompliant" or "Unknown"

### 1.2 Check Intune Audit Logs for Enrollment Anomalies

```powershell
# Search audit logs for enrollment events
$auditLogs = Invoke-MgGraphRequest -Method GET `
  -Uri "/beta/auditLogs/directoryAudits?`$filter=resources/any(r:r/displayName eq 'DESKTOP-FB099')"

# Filter for enrollment-related activities
$auditLogs.value | Where-Object { $_.activity -match 'Enroll|Retire|Delete' } | 
  Select-Object @('activityDateTime', 'activity', 'result', 'initiatedBy') | 
  Format-Table -Wrap
```

**Expected pattern:**
- 2023-11-04 (approx): "Enroll device" (legacy MDM enrollment)
- 2024-03-15: "Enroll device" (Autopilot enrollment attempt — should fail or block)
- **Missing:** No "Retire device" or "Delete device" between legacy and Autopilot enrollments
- **Also missing:** No evidence of `dsregcmd /leave` execution

### 1.3 Check Device Compliance Policy Status

```powershell
# Get device compliance status
$complianceStatus = Invoke-MgGraphRequest -Method GET `
  -Uri "/beta/deviceManagement/deviceCompliancePolicies/POLICY_ID/deviceStatuses?`$filter=deviceName eq 'DESKTOP-FB099'"

$complianceStatus.value | Select-Object @(
  'displayName',
  'status',
  'lastReportedDateTime'
) | Format-Table

# Expected output:
# status should be "NonCompliant" or "Error" for all 4 policies
# lastReportedDateTime should be 2024-03-15 and not update
```

---

## Step 2: Query Device Local State

### 2.1 Run dsregcmd Status Check

**On affected device (local or remote via Intune):**

```powershell
# Run as Administrator
dsregcmd /status

# Look for these fields:
# - Device Name: DESKTOP-FB099
# - Workplace Join Status: Joined
# - MDM Url: Should show Intune endpoint or be EMPTY if clean
# - Device Id: Should match Azure AD device ID
```

**Interpretation:**
- **MDM Url shows Intune enrollment URL:** Device thinks it's still in legacy MDM
- **MDM Url shows different endpoint:** Third-party MDM or legacy management system still active
- **MDM Url is empty or missing:** Device has been properly deregistered

### 2.2 Check Enrollment Cache File

```powershell
# On affected device, check if enrollment cache exists
$enrollmentCache = "$env:ProgramData\Microsoft\Enrollment\Status\EnrollmentResult.json"

if (Test-Path $enrollmentCache) {
    Write-Host "Enrollment cache found"
    Get-Content $enrollmentCache | ConvertFrom-Json | Format-List
} else {
    Write-Host "Enrollment cache not found (clean state)"
}

# Expected finding: Cache shows legacy enrollment details from 2023-11-04
# or shows failed Autopilot enrollment from 2024-03-15
```

### 2.3 Check Event Viewer for Enrollment Errors

```powershell
# On affected device, query event logs
Get-EventLog -LogName "System" -Source "Microsoft-Windows-DeviceManagement-Enterprise-Diagnostic-Provider" `
  -EventId 7009 | Select-Object -First 10 | Format-List TimeGenerated, Message

# Also check:
Get-WinEvent -FilterHashtable @{
  LogName = 'Application'
  ProviderName = 'MDMRegistrationAuxiliaryService'
} -ErrorAction SilentlyContinue | Select-Object -First 10 | Format-List
```

**Expected findings:**
- Event IDs related to enrollment failure
- Error messages mentioning "device already enrolled" or MDM conflicts
- Timestamps around 2024-03-15 09:18:44 UTC

### 2.4 Check Intune Management Extension Status

```powershell
# On affected device, check IME service
$imeService = Get-Service -Name "IntuneManagementExtension" -ErrorAction SilentlyContinue

if ($imeService) {
    Write-Host "Status: $($imeService.Status)"
    Write-Host "Startup Type: $($imeService.StartType)"
} else {
    Write-Host "IME Service not found"
}

# Check IME logs
$imeLogs = Get-EventLog -LogName "Application" -Source "IntuneManagementExtension" -ErrorAction SilentlyContinue
$imeLogs | Select-Object -First 20 | Format-Table TimeGenerated, EventID, Message -Wrap
```

---

## Step 3: Root Cause Confirmation Decision Tree

```
Does device have ERROR or UNKNOWN compliance status?
├─ YES → Continue to Step 4 (Remediation)
└─ NO → Check if device is actually compliant
        ├─ YES → Ticket may be resolved already; verify user access
        └─ NO → Investigate other compliance issues (BitLocker, Secure Boot, etc.)

Is MDM Url in dsregcmd /status showing legacy enrollment?
├─ YES → Legacy enrollment is active; continue to Step 4
└─ NO → Enrollment state may be clean; verify dsregcmd shows no MDM Url

Is enrollment cache file present with old enrollment data?
├─ YES → Confirms legacy enrollment cached locally; continue to Step 4
└─ NO → May indicate partial cleanup already attempted

Are audit logs missing deprovisioning step between enrollments?
├─ YES → Confirms legacy enrollment was never formally retired
└─ NO → Deprovisioning may have been attempted; investigate failure

DIAGNOSIS CONFIRMED: Stale MDM enrollment blocking Autopilot
→ PROCEED TO STEP 4: REMEDIATION
```

---

## Step 4: Remediation Execution

### 4.1 Delete Device from Intune

```powershell
# In Intune admin center (PowerShell or UI)
# Option A: PowerShell
$deviceId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"  # Get from Intune
Invoke-MgGraphRequest -Method DELETE `
  -Uri "/beta/deviceManagement/managedDevices/$deviceId"

# Option B: UI Path
# Intune admin center > Devices > All devices > DESKTOP-FB099 > Delete > Confirm
```

**Verification:**
```powershell
# Wait 10-15 minutes, then verify device is gone
$device = Invoke-MgGraphRequest -Method GET `
  -Uri "/beta/deviceManagement/managedDevices?`$filter=deviceName eq 'DESKTOP-FB099'"

if ($device.value.Count -eq 0) {
    Write-Host "Device successfully deleted from Intune"
} else {
    Write-Host "Device still present; wait longer or retry delete"
}
```

### 4.2 Clear Local Enrollment State on Device

**On affected device (local admin or remote):**

```powershell
# Step 1: Leave Azure AD
dsregcmd /leave

# Wait for command to complete - should show "Device leave succeeded"

# Step 2: Verify clean state
dsregcmd /status
# Expected: No MDM Url, no device ID for Azure AD

# Step 3: Delete enrollment cache
$cache = "$env:ProgramData\Microsoft\Enrollment\Status\EnrollmentResult.json"
if (Test-Path $cache) {
    Remove-Item -Path $cache -Force
    Write-Host "Enrollment cache cleared"
}

# Step 4: Delete Intune registry entries
$regPath = "HKLM:\SOFTWARE\Microsoft\Enrollments"
if (Test-Path $regPath) {
    Get-ChildItem -Path $regPath | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Intune enrollment registry entries cleared"
}

# Step 5: Reboot device
Restart-Computer -Force
```

### 4.3 Wait for Propagation

After deletion and local cleanup:
```
Timeline:
T+0 min:    Device deleted from Intune, local state cleared
T+5 min:    Azure AD deletion should propagate
T+10 min:   Intune database sync should complete
T+15 min:   Safe to verify device is not in Intune anymore
T+20 min:   Safe to trigger re-enrollment
```

### 4.4 Verify Device Removal

```powershell
# After 15 minutes, confirm device is fully removed
$search = Invoke-MgGraphRequest -Method GET `
  -Uri "/beta/deviceManagement/managedDevices?`$filter=deviceName eq 'DESKTOP-FB099'"

$azureADDevice = Get-MgDevice -Filter "displayName eq 'DESKTOP-FB099'" -ErrorAction SilentlyContinue

if ($search.value.Count -eq 0 -and $null -eq $azureADDevice) {
    Write-Host "Device fully removed from both Intune and Azure AD"
} else {
    Write-Host "Device still present in at least one system; investigate further"
    # If device is in Azure AD but not Intune, may need manual Azure AD deletion
}
```

### 4.5 Re-Trigger Autopilot Enrollment

**Option A: Device Autopilot Reset (Recommended)**

```powershell
# On the device, trigger Autopilot reset
# Settings > System > Recovery > Reset this PC > Keep my files
# This will invoke Autopilot ESP (Enrollment Status Page) and re-enroll

# Or via PowerShell:
$registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Enrollment"
New-Item -Path $registryPath -Force | Out-Null
New-ItemProperty -Path $registryPath -Name "DiscoverAllowedToFail" -Value 0 -Type DWord -Force | Out-Null

# Then run:
& "$env:SystemRoot\System32\schtasks.exe" /run /tn "\Microsoft\Windows\Application Experience\StartupTask" /force
```

**Option B: Administrative Force Re-Sync**

```powershell
# On the device:
gpupdate /force

# Or trigger via Intune if device re-appears in Intune admin center:
# Intune admin center > Devices > [Device] > Sync Device
```

**Option C: Provision Package (Advanced)**

If device doesn't respond to above, consider Windows Configuration Designer provisioning package with Autopilot settings, but this is complex and should only be used by experienced admins.

### 4.6 Monitor Re-Enrollment Progress

```powershell
# Monitor device for re-appearance in Intune
# Run this check every 5 minutes for 30 minutes:

$device = Invoke-MgGraphRequest -Method GET `
  -Uri "/beta/deviceManagement/managedDevices?`$filter=deviceName eq 'DESKTOP-FB099'"

if ($device.value.Count -gt 0) {
    $dev = $device.value[0]
    Write-Host "Device re-appeared in Intune"
    Write-Host "  Enrollment Type: $($dev.enrollmentType)"
    Write-Host "  Enrollment DateTime: $($dev.enrollmentDateTime)"
    Write-Host "  Management State: $($dev.managementState)"
    Write-Host "  Compliance State: $($dev.complianceState)"
} else {
    Write-Host "Still waiting for device to re-appear..."
}
```

---

## Step 5: Verification and Validation

### 5.1 Verify Device Re-Enrollment Success

```powershell
# Check enrollment is now Autopilot
$device = Invoke-MgGraphRequest -Method GET `
  -Uri "/beta/deviceManagement/managedDevices?`$filter=deviceName eq 'DESKTOP-FB099'"

$dev = $device.value[0]

Write-Host "Enrollment Type: $($dev.enrollmentType)" # Should be "Autopilot"
Write-Host "Enrollment Date: $($dev.enrollmentDateTime)" # Should be today (2026-08-11 or later)
Write-Host "Management State: $($dev.managementState)" # Should be "Managed"
Write-Host "Last Sync: $($dev.lastSyncDateTime)" # Should be recent
```

**Pass Criteria:**
- ✅ `enrollmentType` = "Autopilot"
- ✅ `enrollmentDateTime` = 2026-08-11 or later
- ✅ `managementState` = "Managed"
- ✅ `lastSyncDateTime` is within last 5 minutes

### 5.2 Verify Policies Are Applying

```powershell
# Check compliance policy status
$compliance = Invoke-MgGraphRequest -Method GET `
  -Uri "/beta/deviceManagement/deviceCompliancePolicies"

$policies = $compliance.value
foreach ($policy in $policies) {
    $status = Invoke-MgGraphRequest -Method GET `
      -Uri "/beta/deviceManagement/deviceCompliancePolicies/$($policy.id)/deviceStatuses?`$filter=deviceName eq 'DESKTOP-FB099'"
    
    if ($status.value) {
        $deviceStatus = $status.value[0]
        Write-Host "Policy: $($policy.displayName)"
        Write-Host "  Status: $($deviceStatus.status)" # Should be "Compliant" or "NonCompliant" (not "Error")
        Write-Host "  Last Report: $($deviceStatus.lastReportedDateTime)"
    }
}
```

**Pass Criteria:**
- ✅ All 4 policies show status "Compliant" or "NonCompliant" (NOT "Error" or "Unknown")
- ✅ All policies have recent `lastReportedDateTime` (within 5 minutes)
- ✅ No "Access denied" or "0x80070005" errors in logs

### 5.3 Verify User Can Access Corporate Resources

```powershell
# On the device, verify user can:
# 1. Access Microsoft Teams
#    - Teams should open and show channel list
#    - No Conditional Access error message

# 2. Access Outlook
#    - Outlook should open and show inbox
#    - No "Your organization requires device compliance" block

# 3. Access OneDrive
#    - OneDrive should sync and show file list
#    - No authentication errors

# 4. Access SharePoint
#    - Should be able to access SharePoint sites
#    - No Conditional Access blocks
```

---

## Step 6: Troubleshooting Common Issues During Remediation

### Issue: Device still appears in Intune 30 minutes after deletion

**Cause:** Intune database cache not synced

**Resolution:**
```powershell
# Force Intune database refresh
Invoke-MgGraphRequest -Method POST `
  -Uri "/beta/deviceManagement/managedDevices/{device-id}/remoteLock"

# Or retry deletion if device ID still exists
# Wait another 15 minutes and check again
```

### Issue: dsregcmd /leave fails or hangs

**Cause:** Azure AD service or network connectivity issue

**Resolution:**
```powershell
# Try alternative method to leave Azure AD
Remove-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Services\AAD" -Recurse -Force -ErrorAction SilentlyContinue

# Or boot into Safe Mode with Networking and retry dsregcmd /leave

# Check connectivity to login.microsoftonline.com
Test-Connection login.microsoftonline.com -Quiet
Test-Connection enrollment.manage.microsoft.com -Quiet
```

### Issue: Re-enrollment starts but fails midway with different error

**Cause:** Autopilot profile missing or device not in Autopilot group

**Resolution:**
```powershell
# Verify Autopilot profile exists
$autopilotProfiles = Invoke-MgGraphRequest -Method GET `
  -Uri "/beta/deviceManagement/deviceEnrollmentConfigurations"

$profiles = $autopilotProfiles.value | Where-Object { $_.displayName -match "Autopilot" }

# Verify device is assigned to Autopilot profile group
# Check Azure AD group membership:
Get-MgGroupMember -GroupId $groupId | Where-Object { $_.displayName -eq 'DESKTOP-FB099' }
```

### Issue: Compliance shows "NonCompliant" instead of "Compliant" after re-enrollment

**Cause:** Device may need additional time for compliance evaluation, or BitLocker/Secure Boot not fully enabled

**Resolution:**
```powershell
# Wait 24 hours for compliance evaluation to complete (often in grace period first)

# Check which compliance requirement is failing:
$compliance = Invoke-MgGraphRequest -Method GET `
  -Uri "/beta/deviceManagement/deviceCompliancePolicies/POLICY_ID/deviceStatuses?`$filter=deviceName eq 'DESKTOP-FB099'"

# Review each setting for false positives (BitLocker in progress, Secure Boot firmware state, etc.)
# Most compliance issues resolve within 7-day grace period
```

---

## Step 7: Permanent Prevention (L2/L3 Action Items)

### Automation: Pre-Enrollment Validation Script

Create and deploy this PowerShell script before any future Autopilot re-enrollment:

```powershell
# File: Validate-AutopilotPreRequisites.ps1
param([string]$DeviceName)

Write-Host "Validating pre-enrollment prerequisites for $DeviceName..."

# Check 1: Is device in Intune?
$intuneDevice = Invoke-MgGraphRequest -Method GET `
  -Uri "/beta/deviceManagement/managedDevices?`$filter=deviceName eq '$DeviceName'"

if ($intuneDevice.value.Count -gt 0) {
    Write-Error "Device already exists in Intune. Deprovisioning required."
    return $false
}

# Check 2: Is device in Azure AD?
$azureDevice = Get-MgDevice -Filter "displayName eq '$DeviceName'"

if ($azureDevice) {
    Write-Warning "Device exists in Azure AD. Will be handled by Azure AD cleanup."
}

# Check 3: Is device assigned to Autopilot profile?
$autopilotProfile = Get-AutoPilotDevice -SerialNumber $serialNumber
if (-not $autopilotProfile) {
    Write-Error "Device not found in Autopilot. Assignment required."
    return $false
}

# Check 4: Is user licensed for Intune?
$user = Get-MgUser -UserId $username
$licenses = Get-MgUserLicenseDetail -UserId $username | Where-Object { $_.skuPartNumber -match "Intune|EMS" }

if (-not $licenses) {
    Write-Error "User not licensed for Intune."
    return $false
}

Write-Host "All pre-requisites validated. Safe to proceed with enrollment."
return $true
```

Deploy this script to run BEFORE enrollment is triggered.

### Monitoring: Enrollment Error Alert

Set up monitoring for enrollment failures:

```powershell
# Create alert rule in Azure Monitor/Logic Apps
# Trigger: Device with enrollment status = "Failed" for >24 hours
# Action: Send email to Intune admin team with device details
# Body: Include device name, error code, enrollment date, recommended action

# Example Logic App trigger:
# Query Intune API every 4 hours for devices with enrollmentState = "Failed"
# If found, email report to [intune-admins@company.com] with remediation link
```

---

## Appendices

### Appendix A: PowerShell Module Requirements

```powershell
# Install required modules
Install-Module -Name Microsoft.Graph -RequiredVersion 1.0 -Force
Install-Module -Name WindowsAutoPilotIntune -Force

# Connect to Graph API
Connect-MgGraph -Scopes "Device.ReadWrite.All", "DeviceManagementServiceConfig.ReadWrite.All"

# Test connectivity
Get-MgOrganization # Should return your organization details
```

### Appendix B: Common Error Codes Reference

| Code | Meaning | Action |
|---|---|---|
| `0x80180014` | Device already enrolled in MDM | Follow remediation in Step 4 |
| `0x80070005` | Access denied | Usually secondary to 0x80180014; resolves when primary error fixed |
| `0x800705B4` | Enrollment not complete | Device stuck in enrollment state; may need OOBE restart |
| `0x80180001` | Enrollment general failure | May be network or certificate issue; test connectivity |

### Appendix C: Useful Intune URLs and Paths

- Devices: `https://endpoint.microsoft.com/#blade/Microsoft_Intune_DeviceSettings/DevicesMenuBlade/AllDevices`
- Compliance Policies: `https://endpoint.microsoft.com/#blade/Microsoft_Intune_Devices/ComplianceMenuBlade/policies`
- Autopilot Profiles: `https://endpoint.microsoft.com/#blade/Microsoft_Intune_HAAD/AutopilotDeploymentProfilesBlade/profilesBlade`
- Audit Logs: `https://endpoint.microsoft.com/#blade/Microsoft_Intune_Auditing/AuditBlade`

---

**Created:** 2026-08-11  
**Version:** 1.0  
**Review Date:** 2026-09-30

*This guide is for L2/L3 support staff with Intune admin access. For L1 support, refer to KB-AUTO-L1-001.*
