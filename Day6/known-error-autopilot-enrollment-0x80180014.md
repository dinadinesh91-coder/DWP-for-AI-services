# Known Error Record — Autopilot Enrollment Failure Error 0x80180014
## "The Device is Already Enrolled in MDM"

**KE ID:** KE-2024-0315-001  
**Status:** Active (Permanent Fix Targeted 2026-09-30)  
**Severity:** High  
**Component:** Intune | Autopilot | Device Enrollment  
**First Occurrence:** 2024-03-15  
**Affected Devices:** At least 1 confirmed (DESKTOP-FB099); potentially others  
**Last Updated:** 2026-08-11  

---

## Error Identification

| Attribute | Value |
|---|---|
| **Error Code** | 0x80180014 |
| **Error Message** | "The device is already enrolled in MDM" |
| **Component Reporting Error** | Intune Enrollment Service |
| **Enrollment Type** | Autopilot |
| **Trigger Timestamp** | 2024-03-15 09:18:44 UTC |
| **Secondary Error Code** | 0x80070005 (Access denied on policy application) |

---

## Symptoms

Users or administrators attempting to re-enrol a device in Autopilot will experience:

- **Autopilot enrollment fails** with error code `0x80180014` immediately after enrollment trigger
- **No policies are applied** — device shows 0 of 4 policies applied in Intune policy manager
- **Policy manager log shows** `LastError: 0x80070005 (Access denied)` on profile `FinBridge-Win11-Security-Baseline`
- **Compliance engine cannot evaluate** — device compliance status shows "Error" or "Unknown"
- **Conditional Access blocks access** — user cannot sign in to Microsoft 365 services because compliance cannot be evaluated
- **Device appears enrolled but is non-functional** — enrolls successfully, but policies and compliance checks fail
- **Issue persists across reboots** — problem does not self-resolve with time or device restart

---

## Root Cause

A legacy MDM enrollment from a previous enrollment cycle (typically November 2023 or earlier) was not deprovisioned before Autopilot re-enrollment was triggered. Intune's enrollment service blocks new Autopilot enrollments when an existing MDM enrollment already exists for that device in the Intune database.

**Why it occurs:**
- Device was originally enrolled in legacy MDM (manual enrollment)
- Decision was made to migrate device to Autopilot profile
- Device deprovisioning step was either skipped, failed, or not verified to complete
- Autopilot re-enrollment was triggered while legacy enrollment was still active in Intune
- Intune rejects the enrollment request with error code 0x80180014

**Why policies fail with 0x80070005:**
Policies assigned to the Autopilot profile cannot be delivered to a device that is still enrolled under the legacy MDM context. Intune denies policy delivery due to enrollment scope mismatch, resulting in "Access denied" error.

---

## Affected Devices and Scope

### **Confirmed Affected**
- **DESKTOP-FB099** (FINBRIDGE\rthomas)
  - Enrollment attempt: 2024-03-15
  - Current status: Non-compliant, non-functional
  - Duration: ~1 year

### **Likely Affected (Audit Required)**
Any device meeting ALL of the following criteria:
- Enrolled between 2024-03-01 and 2024-03-31 (timeframe of first observed failure)
- Assigned to an Autopilot profile (e.g., `FinBridge-Autopilot-Standard`)
- Has a prior enrollment date from 2023 or earlier
- Shows zero policies applied despite successful enrollment
- Compliance status shows "Error" or "Unknown"

---

## Workaround (Immediate Resolution)

**For User/Device Support:**

Users experiencing this error can request immediate remediation from IT Support with the following information:
- Device name (e.g., DESKTOP-FB099)
- Any Intune compliance policy names assigned

**For IT Support/Administrators:**

Follow this procedure to resolve the error for an affected device:

### **Step 1: Verify the Issue (5 minutes)**

1. In Intune admin center, navigate to **Devices > All devices > [Device Name]**.
2. Check the device's enrollment type (should show "Autopilot" or blank if enrollment failed).
3. Check the enrollment date (if prior to 2024-03-15 and device is in this scenario, it's the legacy enrollment).
4. Open **Device compliance** and confirm status is "Error", "Unknown", or "Not evaluated".

### **Step 2: Deprovisioned from Intune (5 minutes)**

1. In Intune admin center, locate **Devices > All devices > [Device Name]**.
2. Select the device and click **Delete** (or **Retire** if you need to preserve logs; Delete is preferred for complete cleanup).
3. Confirm the delete action.
4. Wait 10–15 minutes for the deletion to propagate through Intune and Azure AD services.

### **Step 3: Clear Local Device State (5 minutes)**

On the affected device (must have local admin access):

1. Open PowerShell as Administrator.
2. Run the following commands:
   ```powershell
   # Leave Azure AD and clear enrollment
   dsregcmd /leave
   
   # Wait for completion, then verify
   dsregcmd /status
   ```
3. Expected output from `dsregcmd /status`: Should NOT show an MDM URL or should show "Not joined to Azure AD"
4. Delete the enrollment cache:
   ```powershell
   Remove-Item -Path "$env:ProgramData\Microsoft\Enrollment\Status\EnrollmentResult.json" -Force
   ```
5. Reboot the device.

### **Step 4: Verify Device Is Removed from Intune (5 minutes)**

1. Wait 5 minutes after reboot.
2. In Intune admin center, search for the device by name or serial number in **Devices > All devices**.
3. Confirm device does NOT appear in the list.
4. If device still appears: Repeat Step 2 and wait another 15 minutes.

### **Step 5: Re-Trigger Autopilot Enrollment (5–30 minutes)**

Once the device is removed, re-enroll using one of these methods:

**Option A: Autopilot Reset (Recommended for user devices)**
1. On the device, open **Settings > System > Recovery**.
2. Click **Reset this PC**.
3. Select **Keep my files**.
4. Follow the prompts to reset (this will invoke Autopilot ESP).
5. Device will reboot multiple times and re-enroll automatically.

**Option B: Administrative Force Enrollment**
1. On the device, run: `gpupdate /force`
2. Monitor Intune **Devices > All devices** for the device to re-appear.

**Option C: Intune Re-Sync**
1. In Intune, find the device in **Devices > All devices** and select **Sync**.
2. Wait for sync to complete and device to re-enroll.

### **Step 6: Verify Resolution (10 minutes)**

1. In Intune admin center, navigate to **Devices > All devices** and find the device.
2. Confirm **Enrollment type** now shows **"Autopilot"** and **Enrollment date** is today (2024-03-15 or later).
3. Open **Device compliance** and confirm status is **"Compliant"** or **"In grace period"** (not "Error" or "Unknown").
4. Check **Device compliance > [Policy Name]** and verify all 4 policies show status "Compliant" or "In grace period" with no "Error" entries.
5. On the device, verify user can sign in to Microsoft 365 services (Teams, Outlook, etc.) without Conditional Access blocks.

**Expected Outcome:** Device is now functional, compliant, and can access corporate resources.

---

## Permanent Fix (Long-Term)

Permanent fixes are in development and targeted for implementation by 2026-09-30:

| Fix | ETA | Details |
|---|---|---|
| **Updated Autopilot Runbook** | 2026-08-31 | Pre-enrollment validation checklist and deprovisioning procedures documented and mandatory |
| **Automated Pre-Enrollment Validation Script** | 2026-08-31 | PowerShell script to automatically detect and prevent dual enrollments |
| **Enrollment State Monitoring Alert** | 2026-09-15 | Proactive alert system for devices with enrollment errors lasting >24 hours |
| **IT Staff Training** | 2026-09-15 | Mandatory training on Autopilot migration scenarios and device deprovisioning |
| **Microsoft Enhancement Request** | Pending | Request to Microsoft for Intune to auto-deprovisioned legacy enrollments when Autopilot enrollment is triggered for the same device |

---

## Known Workaround Limitations

- **Requires local admin access** on affected device — if device is inaccessible, remote remediation may be required
- **Data loss risk** if "Autopilot Reset" option is selected without understanding full device reset implications — recommend "Keep my files" option
- **Time-consuming** for large scale — manual remediation is required per device; no bulk automation in place yet
- **Does not prevent future occurrences** on other devices — requires preventive measures (updated runbook, validation scripts)

---

## Related Errors

| Error Code | Error Message | Relationship |
|---|---|---|
| **0x80180014** | Device is already enrolled in MDM | Primary error — enrollment blocked |
| **0x80070005** | Access denied | Secondary error — policy delivery fails due to enrollment scope mismatch |
| **0x800705B4** | Enrollment not complete | Tertiary error — compliance cannot evaluate while enrollment is blocked |

---

## Escalation Criteria

Escalate to **Intune Administrator** if:
- Issue persists after following the workaround steps
- Device does not appear to be removing from Intune even after deletion (may indicate database sync issue)
- Device deletion completes but Autopilot re-enrollment still fails with the same error (may indicate Autopilot profile configuration issue)
- Multiple devices (>10) are found with this error (may indicate systematic issue requiring bulk remediation)

---

## References

- [RCA Document](rca-autopilot-desktop-fb099-2024-03-15.md)
- [L2/L3 KB — Advanced Troubleshooting](kb-l2l3-autopilot-enrollment-troubleshooting.md)
- [L1 KB — Help Desk Guide](kb-l1-autopilot-enrollment-support.md)

---

## Known Error Status History

| Date | Status | Notes |
|---|---|---|
| 2024-03-15 | Identified | First occurrence on DESKTOP-FB099 |
| 2024-03-16 | Escalated | Assigned for RCA |
| 2026-08-11 | RCA Completed | Root cause identified; preventive actions initiated |
| 2026-08-31 | Permanent Fix Expected | Runbook and automation updates targeted |
| 2026-09-30 | Closure Target | All preventive actions implemented; no new cases expected |

---

## Support Contact

For assistance with this known error, contact:
- **L1 Help Desk:** [support email/phone]
- **Intune Admin:** [team email/Slack channel]
- **Escalation:** [manager contact]

---

*Known Error Record Created: 2026-08-11  
Record Version: 1.0  
Next Review: 2026-09-30*
