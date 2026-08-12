# Autopilot Enrolment Failure Analysis — DESKTOP-FB099

**Device:** DESKTOP-FB099  
**User:** FINBRIDGE\rthomas  
**Date:** 2024-03-15  

---

## Ranked Causes — Most Probable First

### **1. Legacy MDM Enrolment Still Active in Intune (Blocking Re-enrolment)**

**Why it fits the evidence:**
- Error `0x80180014` explicitly states "The device is already enrolled in MDM."
- Device records show `MDMEnrolled: Yes (previous enrolment from 2023-11-04)`.
- Autopilot cannot re-enrol a device with an active MDM enrollment — it must be unenrolled first.
- The legacy enrolment is ~8 months old and likely still active in Intune's records.

**Fastest check to confirm or eliminate:**
1. In Intune admin center, navigate to **Devices > All devices > DESKTOP-FB099 > Device details**.
2. Check the **Enrolled date** and **Last check-in** fields — if both show dates from 2023, the enrollment is stale but may still be blocking re-enrolment.
3. Run on the device: `dsregcmd /status` and check the **MDM URL** line — if it shows a non-Autopilot enrollment URL, confirm the legacy enrollment is still tied to the device.

**Specific remediation if confirmed:**
1. In Intune, select **DESKTOP-FB099 > Delete** (or **Retire** if you need to preserve logs) to remove the device record entirely.
2. Wait 5–10 minutes for the deletion to propagate.
3. On the device, clear local enrollment state: Run `dsregcmd /leave` (removes Azure AD) and `%programdata%\Microsoft\Enrollment\Status\EnrollmentResult.json` (clears enrollment cache).
4. **Reboot the device.**
5. Trigger Autopilot re-enrollment: `Autopilot Reset` in Settings > System > Recovery, or force re-enrollment via `gpupdate /force` and Group Policy-triggered Autopilot.

---

### **2. User (rthomas) Lacks Permissions to Receive FinBridge Security Policies**

**Why it fits the evidence:**
- Policy manager shows `LastError: 0x80070005 (Access denied)` — `0x80070005` is the standard Windows **ACCESS_DENIED** error.
- Specific policy failure: `FinBridge-Win11-Security-Baseline` — suggests the device cannot apply security baselines due to insufficient privileges or group membership.
- Zero profiles applied (`ProfilesApplied: 0 of 4`) despite successful Azure AD join, which suggests policy assignment scope issue rather than enrollment state issue.
- User is `FINBRIDGE\rthomas` — if rthomas is not in the correct device group or security group for FinBridge policies, access will be denied.

**Fastest check to confirm or eliminate:**
1. In Intune admin center, open **Devices > Compliance policies > [any policy] > Assignments** and verify DESKTOP-FB099 (or its group) is listed.
2. Cross-check in Intune: **Groups > Device groups** — confirm DESKTOP-FB099 or a group containing it is in scope for the `FinBridge-Win11-Security-Baseline` policy.
3. On the device, check the **Event Viewer > Applications and Services Logs > Microsoft > Windows > DeviceManagement-Enterprise-Diagnostic-Provider > Operational** for events mentioning policy GUID and access denied.

**Specific remediation if confirmed:**
1. Add DESKTOP-FB099 to the device group assigned to the `FinBridge-Win11-Security-Baseline` policy (if using dynamic groups, verify the rule includes this device).
2. Verify the device's Azure AD object has the correct `deviceType` and group membership attributes.
3. Manually trigger policy refresh on the device: `gpupdate /force` (if GPO-backed) or restart Intune Management Extension.
4. Reboot the device.
5. Monitor **Intune > Devices > [device] > Device compliance** to confirm policies now apply.

---

### **3. Stale Enrollment Record in Intune Not Properly Cleaned Up from Previous Migration**

**Why it fits the evidence:**
- Legacy enrollment is 8 months old (2023-11-04) — suggests a prior device deployment or migration cycle.
- Device is Azure AD joined and licensed correctly, but Intune has a "ghost" record that is neither fully active nor fully removed.
- Autopilot checks Intune's device database and sees an existing enrollment, preventing the new Autopilot enrollment from proceeding.
- Access denied on policy application suggests the stale record has lost sync with the device's actual state — policies are assigned to a different enrollment context.

**Fastest check to confirm or eliminate:**
1. In Intune admin center, open **Audit logs** and search for `DESKTOP-FB099` with `Activity: Enroll device`.
2. Check if there are two separate enrollment events — one from 2023 (legacy) and none from 2024-03-15 (failed Autopilot attempt).
3. Compare the enrollment record's **Management URL** and **Management Authority** fields — if they differ from the current Autopilot profile (`FinBridge-Autopilot-Standard`), confirm a stale record is blocking the new one.

**Specific remediation if confirmed:**
1. In Intune, navigate to **Devices > All devices > DESKTOP-FB099**.
2. Select **Delete** to remove the stale record from Intune's database entirely (not just retire).
3. Allow 10–15 minutes for Intune and Azure AD to synchronise.
4. On the device, run: `dsregcmd /leave` to clear local Azure AD cache, then reboot.
5. Re-trigger Autopilot enrollment via **Settings > System > Recovery > Reset this PC (Keep my files) > Reset** (which will invoke Autopilot ESP) or via the Autopilot Reset feature.
6. Monitor the Intune **Devices > All devices** page for a new enrollment record to appear with today's date.

---

## Summary

**Most probable sequence:** Legacy enrollment blocks re-enrollment (cause #1) → Access denied error occurs because policies assigned to Autopilot profile cannot be delivered to a device in legacy enrollment state (cause #2) → stale record remains in Intune (cause #3, compounding effect).

**First action:** Delete the device record in Intune and clear local enrollment state before re-triggering Autopilot.

---

*Analysis created: 2026-08-11*
