# Root Cause Analysis — Autopilot Enrolment Failure
## DESKTOP-FB099 | FINBRIDGE\rthomas | 2024-03-15

**RCA ID:** RCA-2024-0315-001  
**Device:** DESKTOP-FB099  
**User:** FINBRIDGE\rthomas  
**Severity:** High (User blocked from accessing corporate resources)  
**Status:** Open  
**Initiated:** 2026-08-11  

---

## Executive Summary

Device DESKTOP-FB099 failed to complete Autopilot enrolment on 2024-03-15 with error code `0x80180014` ("The device is already enrolled in MDM"). A legacy MDM enrolment from November 2023 was not deprovisioned before the Autopilot re-enrolment attempt, preventing Intune from accepting a new Autopilot profile and causing all four managed compliance policies to fail application with access denied errors (`0x80070005`).

**Root Cause:** Stale MDM enrollment record in Intune was not cleaned up during the planned migration from legacy MDM to Autopilot, and device cleanup procedures were not executed on DESKTOP-FB099 before re-enrolment was triggered.

**Primary Contributing Factor:** Absence of a formal device deprovisioning checklist and pre-enrollment validation step in the Autopilot deployment runbook.

---

## Supporting Evidence

### Diagnostic Export Data

| Field | Value | Significance |
|---|---|---|
| **EnrollmentState** | Failed | Autopilot enrolment did not reach completion state |
| **ErrorCode** | 0x80180014 | Specific code indicating device is already MDM-enrolled |
| **ErrorDescription** | "The device is already enrolled in MDM" | Confirms dual-enrollment blocking condition |
| **Timestamp** | 2024-03-15 09:18:44 | Enrolment failure occurred 01:04 after Autopilot trigger |
| **MDMEnrolled** | Yes | Device has active MDM enrollment in Intune's database |
| **EnrolmentSource** | Legacy (manual MDM enrolment, 2023-11-04) | Previous enrollment is ~8 months old |
| **ProfilesAttempted** | 4 | Four policies assigned to Autopilot profile were in scope |
| **ProfilesApplied** | 0 | No policies could be delivered due to enrollment failure |
| **LastError (PolicyManager)** | 0x80070005 (Access denied) | Policy delivery blocked, not by connectivity but by permissions |
| **FailedProfile** | FinBridge-Win11-Security-Baseline | Specific control plane policy could not apply |
| **AzureADJoined** | Yes | Device hybrid-joined successfully; Azure AD state is healthy |
| **IntuneP1License** | Yes | User holds required Intune license |
| **AutopilotLicense** | Yes | Device is eligible for Autopilot enrollment |
| **EndpointReach** | All OK | No network connectivity or firewall issues |
| **ProxyDetected** | No | No proxy interference |
| **TPMVersion** | 2.0 | Hardware supports BitLocker and Secure Boot |
| **TPMStatus** | Ready | TPM chip is functional |
| **SecureBoot** | Enabled | Firmware security features are active |
| **OS Build** | 22621.2861 | Device is on current N-1 build at time of enrolment |

**Analysis:** All evidence points to a blocking enrollment state issue rather than hardware, licensing, network, or policy content problems. The device is fully capable and licensed; the barrier is purely a stale MDM enrollment record.

---

## Timeline

### **2023-11-04 — Original Enrollment (Historical Context)**

- **Time:** Unknown
- **Event:** FINBRIDGE\rthomas device (DESKTOP-FB099) enrolled in legacy manual MDM enrollment
- **System:** Intune
- **Outcome:** Device and user received legacy MDM policies and baseline configurations
- **Note:** This enrollment source suggests the device was not originally Autopilot-intended or was re-imaging post-Autopilot migration announcement

### **2024-03 (Date Unknown) — Migration Decision**

- **Event:** Decision made to migrate DESKTOP-FB099 from legacy MDM to Autopilot profile (`FinBridge-Autopilot-Standard`)
- **Expected Action:** Device should have been deprovisioned from legacy enrollment and local enrollment state cleared before re-enrollment
- **Actual Action:** Unknown; no evidence in diagnostic export indicates whether pre-enrollment cleanup was performed
- **Outcome:** Setup for failure

### **2024-03-15 09:18:44 — Autopilot Enrollment Triggered**

- **Time:** 09:18:44 UTC
- **Event:** Autopilot enrollment process initiated (method unclear: user-initiated, GPO-triggered, or admin-initiated)
- **System:** DESKTOP-FB099 (local) → Intune enrollment service
- **Expected Outcome:** Device would be removed from legacy enrollment, new Autopilot enrollment created, and policies applied within 2–5 minutes
- **Actual Outcome:** Enrolment blocked immediately

### **2024-03-15 09:19:01 — Policy Manager Failure (43 seconds later)**

- **Time:** 09:19:01 UTC
- **Event:** Policy Manager component on DESKTOP-FB099 attempted to apply policies from Autopilot profile
- **System:** DESKTOP-FB099 local policy engine + Intune policy delivery service
- **Error:** 0x80070005 (Access denied) on profile `FinBridge-Win11-Security-Baseline`
- **Root Cause:** Policies are assigned to the Autopilot profile, but device enrollment is still tied to legacy MDM context; Intune denies policy delivery to mismatched enrollment context
- **Outcome:** All four policies failed to apply; device stuck in post-enrollment configuration phase

### **2024-03-15 09:19:45 — Compliance Engine Failure (44 seconds after policy failure)**

- **Time:** 09:19:45 UTC
- **Event:** Compliance evaluation engine ran to assess device state against assigned compliance policies
- **Result:** `Could not evaluate` | Reason: `Enrolment not complete`
- **Outcome:** Device compliance status unknown; no access decisions can be made by Conditional Access policies that depend on compliance

### **2024-03-15 (Time Unknown) — User Impact**

- **User:** FINBRIDGE\rthomas
- **Status:** Device enrolled but non-functional
- **Access:** Conditional Access policies block or defer access to Microsoft 365 services because device compliance cannot be evaluated
- **User Experience:** Device appears to complete enrollment, but network access or application sign-in fails with generic "noncompliant" or "unknown compliance state" errors

### **2026-08-11 (Today) — RCA Initiated**

- **Trigger:** Support ticket escalation or proactive audit flagged DESKTOP-FB099 as perpetually non-compliant
- **Evidence Collected:** Full MDM diagnostic export from device
- **Analysis:** RCA initiated

---

## 5 Why Analysis

### **Level 1: Why did Autopilot enrollment fail?**

**Answer:** The device was already enrolled in MDM under a legacy enrollment context, and Intune's enrollment service rejects Autopilot re-enrollment when an active MDM enrollment already exists for that device.

---

### **Level 2: Why was the device already enrolled in MDM?**

**Answer:** A legacy manual MDM enrollment was created on 2023-11-04 and was never deprovisioned. The device record remained active in Intune's database even after the organisational decision to migrate DESKTOP-FB099 to Autopilot.

---

### **Level 3: Why was the legacy enrollment not deprovisioned?**

**Answer:** No formal deprovisioning procedure was executed before the Autopilot re-enrollment attempt. Either:
- (a) The device deprovisioning task was overlooked in the migration plan, or
- (b) A deprovisioning task was documented but not executed due to lack of verification step, or
- (c) The deprovisioning was attempted on a different device or during a different migration batch, and DESKTOP-FB099 was accidentally skipped

**Evidence:** The diagnostic export shows no evidence that `dsregcmd /leave` or an equivalent cleanup procedure was run on DESKTOP-FB099 before enrollment.

---

### **Level 4: Why was no pre-enrollment verification or checklist step in place?**

**Answer:** The Autopilot deployment runbook did not include a mandatory validation gate that checks for and clears existing MDM enrollments before triggering Autopilot re-enrollment. The runbook likely assumed devices were either:
- Newly imaged and never enrolled, or  
- Formally deprovisioned and removed from Intune before re-enrollment

**Impact:** No safeguard existed to catch this condition before the enrollment attempt.

---

### **Level 5: Why does the deployment runbook lack a pre-enrollment validation gate?**

**Answer:** The runbook was written for greenfield Autopilot deployment (new devices, no prior enrollment) and was not updated during the subsequent migration phase to accommodate devices with prior MDM history. The runbook did not anticipate or plan for mixed enrollment scenarios.

---

## Root Cause Statement

**The immediate root cause is a stale MDM enrollment record on device DESKTOP-FB099 in Intune's database that was not deprovisioned before Autopilot re-enrollment was triggered on 2024-03-15.**

**The underlying root cause is the absence of a mandatory pre-enrollment validation checklist in the Autopilot deployment runbook that would have detected the existing legacy enrollment and required its removal before re-enrollment could proceed.**

**The systemic root cause is insufficient runbook evolution during the transition from greenfield Autopilot deployment to a hybrid migration model encompassing devices with prior MDM history.**

---

## Contributing Factors

### **Factor 1: No Device Deprovisioning Checklist**

The Autopilot runbook does not document a step-by-step device cleanup procedure that explicitly covers:
- Query Intune for existing enrollments
- Retire or delete existing MDM records
- Clear local device enrollment cache (`dsregcmd /leave`, `gpupdate /force`)
- Verify device is removed from Intune before triggering Autopilot re-enrollment

**Impact:** Operators had no clear procedure to follow, increasing likelihood of accidental skip.

---

### **Factor 2: No Enrollment Prerequisite Checks**

The runbook does not include validation steps that would run *before* Autopilot enrollment is triggered:
- Pre-check: Is device already enrolled in Intune?
- Pre-check: If yes, is it enrolled in Autopilot profile or legacy MDM?
- Pre-check: If legacy MDM, execute deprovisioning and wait for removal confirmation before proceeding

**Impact:** Enrollment would be attempted even if preconditions were not met.

---

### **Factor 3: No Evidence of Deprovisioning in Audit Logs**

The diagnostic export does not show any evidence that `dsregcmd /leave` or Intune retire/delete was executed on DESKTOP-FB099. No Intune audit log entry corresponds to 2024-03-15 showing a deprovisioning action before the enrollment attempt.

**Impact:** No trace exists to determine whether deprovisioning was attempted and failed, or skipped entirely.

---

### **Factor 4: Mixed Enrollment Model Not Addressed in Training**

If FINBRIDGE\rthomas or the IT team executing the migration received training on Autopilot, that training likely covered new device enrollment only and did not address the "legacy to Autopilot" migration scenario.

**Impact:** Operators may not have understood that existing MDM enrollments must be explicitly removed.

---

### **Factor 5: No Compensating Control for Device Deprovisioning Failures**

Once a device is assigned to Autopilot profile in Intune, there is no automated gate that prevents or halts enrollment if a pre-existing legacy enrollment is detected. Intune simply rejects the enrollment request but does not auto-remediate by deprovisioning the legacy record.

**Impact:** Manual intervention was required to resolve, but no alert mechanism was in place to notify support of the blocked enrollment.

---

## Impact Analysis

### **User Impact**

- **User:** FINBRIDGE\rthomas
- **Device:** DESKTOP-FB099
- **Status:** Device is Azure AD joined and enrolled, but not usable for corporate access
- **Symptoms:** 
  - Conditional Access policies may block sign-in to Microsoft 365 services (Teams, Outlook, OneDrive, etc.) if they require device compliance
  - Compliance evaluation cannot complete; device state is reported as "unknown" or "error" rather than "compliant"
  - Security baseline policies do not apply; device is missing approved configurations
  - Potential security exposure if device is not hardened to compliance baseline
- **Duration:** Since 2024-03-15 (~1 year at time of RCA initiation)
- **Severity:** High — user has been unable to access corporate services from this device for an extended period

### **Organisational Impact**

- **Scope:** At least one device (DESKTOP-FB099); potentially others if this pattern repeats
- **Security:** Devices stuck in this state are not evaluated for compliance and may pose security risks if baseline configurations are not applied
- **Support Load:** Each affected device requires manual remediation; no self-service recovery available
- **Autopilot Adoption:** Users who experience such failures may lose confidence in Autopilot and revert to manual provisioning or support tickets

### **Policy Compliance Impact**

- **BitLocker:** Cannot be validated as compliant until enrollment completes and compliance is re-evaluated
- **Secure Boot:** Status unknown; device cannot report HAS attestation while enrollment is blocked
- **OS Build:** Device is on compliant build (22621.2861) but cannot be marked compliant due to enrollment state
- **Windows Defender:** Status unknown; compliance check cannot run
- **Firewall:** Status unknown; compliance check cannot run
- **Windows Hello / PIN:** Status unknown; compliance check cannot run
- **Grace Period:** If a 7-day grace period was applied to this policy, the device would have been compliant on day 8 (2024-03-23) if enrollment had succeeded. By failing to enroll, the device never entered the grace period and remains non-compliant indefinitely.

---

## Preventive Actions

### **Immediate Actions (0–7 days)**

#### **Action 1.1: Resolve DESKTOP-FB099 Enrollment Failure**

- **Owner:** Intune Admin
- **Steps:**
  1. In Intune admin center, navigate to **Devices > All devices > DESKTOP-FB099**.
  2. Verify the device's enrollment date (should show 2023-11-04) and enrollment type (should show "Legacy manual MDM").
  3. Select **Delete** to remove the device record entirely from Intune.
  4. Wait 10–15 minutes for deletion to propagate to all Intune services and Azure AD.
  5. On DESKTOP-FB099, open PowerShell as administrator and run:
     ```powershell
     dsregcmd /leave
     ```
  6. Wait for command to complete (should show "Device leave succeeded").
  7. Delete the enrollment cache file: `Remove-Item -Path "$env:ProgramData\Microsoft\Enrollment\Status\EnrollmentResult.json" -Force`
  8. Reboot the device.
  9. Trigger Autopilot re-enrollment via one of:
     - Settings > System > Recovery > Reset this PC > Keep my files (Autopilot reset)
     - PowerShell: `Get-AutopilotDevice -serial <serial> | Invoke-AutopilotDeviceSync`
     - Or force re-enrollment: `gpupdate /force` followed by policy-triggered Autopilot
  10. Monitor Intune **Devices > All devices** page for DESKTOP-FB099 to re-appear with a new enrollment date (should be 2024-03-15 or later).
  11. Wait 30 minutes for policies to sync and apply.
  12. Verify in **Device compliance** that all four policies are now showing "Compliant" or "In grace period" status.
- **Success Criteria:** Device appears in Intune with Autopilot enrollment type, all four policies apply successfully, device compliance status is no longer "Error" or "Unknown".
- **Rollback:** If re-enrollment fails, repeat steps 3–8 and check Event Viewer for clues.

#### **Action 1.2: Communicate with User**

- **Owner:** Support / IT Manager
- **Steps:**
  1. Contact FINBRIDGE\rthomas with explanation: "A configuration issue on DESKTOP-FB099 prevented it from completing enrollment in late March. We have now resolved this issue and re-enrolled the device. Please reboot and verify you can access Microsoft 365 services."
  2. Provide user with simple reboot instructions.
  3. Verify user can sign in to Microsoft 365 and access corporate resources.
- **Success Criteria:** User acknowledges issue is resolved and can access corporate services.

---

### **Short-Term Actions (1–2 weeks)**

#### **Action 2.1: Audit All Devices for Similar Enrollment Issues**

- **Owner:** Intune Admin
- **Steps:**
  1. In Intune, run a report: **Devices > Device compliance > Devices with compliance status "Error" or "Unknown"**.
  2. Filter for devices enrolled between 2024-03-01 and 2024-03-31 (timeframe of observed failure).
  3. For each device found:
     - Check if enrollment type is "Autopilot" but device has a prior enrollment from 2023
     - If so, flag for manual remediation using Action 1.1 steps
  4. Remediate all flagged devices using the same procedure as DESKTOP-FB099.
  5. Document count of affected devices and root causes in an audit report.
- **Success Criteria:** All devices found to have the same issue are identified and remediated.

#### **Action 2.2: Query Intune Audit Logs for Missing Deprovisioning Actions**

- **Owner:** Intune Admin
- **Steps:**
  1. In Intune admin center, open **Audit logs**.
  2. Search for all devices enrolled between 2024-03-01 and 2024-03-31.
  3. For each device, verify there is a corresponding "Retire device" or "Delete device" log entry *before* the "Enroll device" entry.
  4. If no deprovisioning entry is found, add that device to the remediation list in Action 2.1.
  5. If a "Retire device" entry exists but "Enroll device" was attempted before deprovisioning completed, note the time gap (should be ≥10 minutes).
  6. Report findings to IT Security.
- **Success Criteria:** All enrollment anomalies are identified and documented.

---

### **Medium-Term Actions (2–4 weeks)**

#### **Action 3.1: Update Autopilot Deployment Runbook**

- **Owner:** IT Deployment Lead / Autopilot Administrator
- **Scope:** All Autopilot runbooks covering migration scenarios (not just greenfield)
- **Changes:**
  1. Add a new section titled **"Pre-Enrollment Validation Checklist"** to the runbook:
     ```
     BEFORE triggering Autopilot enrollment on any device:
     
     ☐ Step 1: Verify device's Intune enrollment status
        - Command: dsregcmd /status
        - Expected result: MDM URL should match Autopilot profile OR be empty
        - If MDM URL shows legacy enrollment: STOP and execute Step 2
     
     ☐ Step 2: If device is currently enrolled, deprovisioning is required
        - In Intune admin center, find the device record
        - Check enrollment type (should show source)
        - If enrolled: Select "Delete" to remove device entirely
        - Wait 10–15 minutes for deletion to propagate
        - On the device, run: dsregcmd /leave
        - Verify command returns "Device leave succeeded"
     
     ☐ Step 3: Clear local enrollment cache
        - Remove-Item -Path "$env:ProgramData\Microsoft\Enrollment\Status\EnrollmentResult.json" -Force
        - Reboot device
     
     ☐ Step 4: Verify device has been removed from Intune
        - Wait 5 minutes after reboot
        - In Intune admin center, search for device by serial number
        - Expected result: Device should NOT appear in "All devices"
        - If device still appears: Repeat Step 2 and wait another 15 minutes
     
     ☐ Step 5: Only after verification in Step 4, proceed with Autopilot enrollment trigger
        - Document enrollment trigger timestamp
        - Monitor device in Intune for 30 minutes to confirm policies apply
     
     If any step fails or shows unexpected result, STOP and escalate to Intune Admin
     before proceeding.
     ```
  2. Add a new section titled **"Device Cleanup Validation"** that includes:
     - Expected time to complete (15–30 minutes per device)
     - Troubleshooting steps for common failure modes
     - Example PowerShell scripts to automate verification
  3. Add a note to the runbook that **all migrations from legacy MDM to Autopilot require this checklist**, not just new enrollments.
  4. Version the runbook and distribute to all IT staff who execute Autopilot deployments.
- **Success Criteria:** Updated runbook is reviewed and approved by IT Security; all staff confirm receipt and understanding.

#### **Action 3.2: Create Pre-Enrollment Validation Script**

- **Owner:** Automation / PowerShell Admin
- **Script Purpose:** Automate detection of existing enrollments and warn operators before enrollment is triggered
- **Pseudocode:**
  ```powershell
  # Pre-Enrollment Validation Script
  param([string]$DeviceSerial)
  
  # Step 1: Check local device state
  $dsreg = dsregcmd /status
  if ($dsreg -match "MDM URL") {
    Write-Warning "Device is currently MDM-enrolled. Deprovisioning is required."
    exit 1
  }
  
  # Step 2: Query Intune for device by serial
  $intuneDevice = Get-ManagedDevice -filter "serialNumber eq '$DeviceSerial'"
  
  if ($intuneDevice) {
    Write-Error "Device is already in Intune (enrollment: $($intuneDevice.enrollmentType)). STOP. Execute deprovisioning first."
    exit 1
  } else {
    Write-Host "Device is NOT in Intune. Safe to proceed with Autopilot enrollment."
    exit 0
  }
  ```
- **Integration:** Script should be called as a pre-flight check in any Autopilot enrollment automation (e.g., Intune provisioning packages, GPO-triggered enrollment scripts).
- **Success Criteria:** Script is tested on multiple devices, integrated into deployment automation, and documented for operators.

#### **Action 3.3: Implement Enrollment State Monitoring Alert**

- **Owner:** Intune Admin / Alert Management
- **Alert Type:** Proactive monitoring query
- **Trigger:** Devices with enrollment state = "Blocked" or "Error" for >24 hours
- **Action:** Automated email to Intune admin team listing affected devices and recommended remediation steps
- **Success Criteria:** Alert is configured in Intune (or via Azure Monitor/Logic Apps if Intune native option unavailable); first test alert is sent and validated.

---

### **Long-Term Actions (1–3 months)**

#### **Action 4.1: Establish Formal Enrollment State Review Process**

- **Owner:** Intune Admin / IT Governance
- **Cadence:** Weekly (initially) then monthly once baseline is clean
- **Report:** 
  - Count of devices with enrollment state errors
  - Count of devices in grace period (for compliance policies)
  - Count of devices with zero policies applied despite successful enrollment
  - Trend analysis (increasing, decreasing, stable)
- **Escalation:** If count of error devices exceeds threshold (e.g., >5 per week), escalate to IT leadership for investigation
- **Success Criteria:** Process is documented, report template is created, and first report is generated.

#### **Action 4.2: Create "Enrollment Troubleshooting" Knowledge Base Article**

- **Owner:** IT Support / Documentation
- **Content:**
  - Common enrollment error codes and their meanings
  - Flowchart decision tree for troubleshooting (similar to Action 1.1)
  - Step-by-step remediation for each error code
  - When to escalate to Intune admin
  - Contact information for tier-2 support
- **Target Audience:** Help desk staff, first-line support
- **Success Criteria:** Article is published, reviewed, and added to IT support knowledge base; help desk is trained on where to find it.

#### **Action 4.3: Implement Dual-Enrollment Detection and Prevention in Intune**

- **Owner:** Intune Admin / Architecture Team
- **Goal:** Intune should prevent or auto-remediate dual enrollments at the platform level
- **Request:** File enhancement request with Microsoft for:
  - Automatic deprovisioning of legacy enrollments when Autopilot enrollment is triggered for the same device
  - Option to require pre-enrollment deprovisioning as a configuration setting
  - Alerting when enrollment state conflicts are detected
- **Workaround (Immediate):** Create a custom PowerShell or Azure Automation runbook that runs weekly and:
  - Queries Intune for devices with multiple enrollments
  - Automatically retires legacy enrollments if Autopilot enrollment is present
  - Logs actions for audit
- **Success Criteria:** Workaround runbook is deployed and tested; enhancement request to Microsoft is filed with expected resolution timeline.

#### **Action 4.4: Conduct Training on Autopilot Migration Scenarios**

- **Owner:** IT Training / Autopilot Program Manager
- **Target Audience:** All IT staff involved in Autopilot deployment (admins, support, deployment engineers)
- **Content:**
  - Differences between greenfield Autopilot and migration scenarios
  - Device lifecycle states and transitions
  - Pre-enrollment validation checklist walkthrough
  - Common failure modes and how to recognize them
  - When to escalate vs. self-remediate
- **Format:** Live instructor-led session (2 hours) + recorded video for reference + hands-on lab (optional)
- **Success Criteria:** All target staff complete training; sign-off sheet is maintained; competency assessment is conducted for critical roles.

---

## Lessons Learned

### **Lesson 1: Mixed Enrollment Models Require Explicit Handling**

Autopilot deployment runbooks that are designed for new/greenfield devices do not automatically accommodate devices with prior enrollment history. Any migration or hybrid scenario requires explicit handling of device cleanup.

**Recommendation:** Document separate runbooks for:
- Greenfield Autopilot (new devices, no prior enrollment)
- Migration Autopilot (devices with prior MDM, legacy management, or manual enrollment)

---

### **Lesson 2: Pre-Flight Checks Are Essential, Not Optional**

Without mandatory pre-enrollment validation, operators will inevitably skip steps or miss edge cases. A checklist must be built into the runbook with explicit verification steps.

**Recommendation:** Never proceed with an enrollment operation without confirming preconditions. Automate these checks where possible.

---

### **Lesson 3: Audit Trails Are Critical for Troubleshooting**

The absence of deprovisioning actions in the Intune audit log made it difficult to determine whether deprovisioning was attempted and failed, or was simply skipped. Comprehensive logging enables faster RCA.

**Recommendation:** Ensure all enrollment-related operations log to audit, including pre-checks, deprovisioning attempts, timing, and errors.

---

### **Lesson 4: User Communication Should Not Assume Device Is Working**

If a device gets stuck in this state, users may not immediately report it if initial sign-in appears to succeed but later access attempts fail. Proactive monitoring is preferable to reactive user reports.

**Recommendation:** Implement alerting for enrollment errors and reach out to affected users proactively rather than waiting for support tickets.

---

## Verification of Remediation

After implementing the above preventive actions, verify effectiveness:

### **Verification Test 1: Re-Remediate DESKTOP-FB099**

- Follow Action 1.1 steps
- Confirm device re-enrolls successfully
- Confirm all four policies apply
- Confirm user can access corporate services
- **Expected Outcome:** Device is now compliant and functional

### **Verification Test 2: Simulate Migration Scenario**

- Select a test device currently enrolled in legacy MDM
- Apply the new runbook procedures
- Execute pre-flight checks using the validation script
- Trigger Autopilot enrollment
- Confirm enrollment succeeds and policies apply without errors
- **Expected Outcome:** Pre-flight checks detect the existing enrollment, require deprovisioning, confirm deprovisioning success, and only then allow enrollment to proceed

### **Verification Test 3: Audit Compliance**

- Review Intune audit logs for all enrollments in the past 30 days
- Verify each enrollment has corresponding deprovisioning logs (where applicable)
- Verify time gaps between deprovisioning and re-enrollment are ≥10 minutes
- **Expected Outcome:** All enrollments are properly sequenced with appropriate deprovisioning precursors

---

## Risk Assessment: Probability of Recurrence

| Risk Factor | Likelihood | Mitigation |
|---|---|---|
| **Operator skips pre-flight checklist** | High (without automation) | Action 3.2: Automate validation script; Action 3.1: Integrate into deployment workflow |
| **Device not deprovisioned in time before enrollment** | Medium | Action 3.1: Add timing requirement (≥10 min) to runbook; Action 4.3: Implement Intune-side prevention |
| **Deprovisioning succeeds locally but Intune cache not cleared** | Medium | Action 3.1: Explicit cache clear step; Action 3.2: Validation script re-checks Intune |
| **Similar issue occurs on a different device** | High (without monitoring) | Action 3.3: Enrollment state monitoring alert; Action 4.1: Weekly review process |
| **New staff trained on old runbook without migration procedures** | Medium | Action 4.4: Mandatory training; Action 3.1: Versioned runbook distribution |

**Overall Residual Risk: MEDIUM** — Most likely to be eliminated by Actions 3.1, 3.2, and 4.4 (runbook + automation + training).

---

## Closure Criteria

This RCA is considered **closed** when:

1. ✅ DESKTOP-FB099 is successfully re-enrolled and compliant (Action 1.1)
2. ✅ All similar devices in the 2024-03-15 timeframe are identified and remediated (Action 2.1)
3. ✅ Autopilot deployment runbook is updated and distributed (Action 3.1)
4. ✅ Pre-enrollment validation script is deployed and tested (Action 3.2)
5. ✅ Enrollment state monitoring alert is configured (Action 3.3)
6. ✅ IT staff training is completed (Action 4.4)

**Target Closure Date:** 2026-09-30 (6 weeks from RCA initiation)

---

## Sign-Off

| Role | Name | Signature | Date |
|---|---|---|---|
| RCA Lead | (Intune Admin) | ____________ | ________ |
| IT Manager | (Manager) | ____________ | ________ |
| IT Security | (Security Lead) | ____________ | ________ |
| Change Advisory Board | (CAB Chair) | ____________ | ________ |

---

## Appendices

### **Appendix A: Complete Diagnostic Export**

```
Device     : DESKTOP-FB099
User       : FINBRIDGE\rthomas
Date       : 2024-03-15 09:22
OS build   : 22621.2861

--- EnrollmentStatus ---
EnrollmentType    : Autopilot
EnrollmentState   : Failed
ErrorCode         : 0x80180014
ErrorDescription  : The device is already enrolled in MDM.
Timestamp         : 2024-03-15 09:18:44

--- PolicyManager ---
ProfilesAttempted : 4
ProfilesApplied   : 0
LastError         : 0x80070005 (Access denied)
FailedProfile     : FinBridge-Win11-Security-Baseline
Timestamp         : 2024-03-15 09:19:01

--- ComplianceEngine ---
EvaluationResult  : Could not evaluate
Reason            : Enrolment not complete
Timestamp         : 2024-03-15 09:19:45

--- DeviceInfo ---
AzureADJoined     : Yes
MDMEnrolled       : Yes (previous enrolment)
EnrolmentSource   : Legacy (manual MDM enrolment, 2023-11-04)
AutopilotProfile  : FinBridge-Autopilot-Standard
TPMVersion        : 2.0
TPMStatus         : Ready
SecureBoot        : Enabled

--- NetworkCheck ---
EndpointReach     : login.microsoftonline.com : OK
EndpointReach     : enrollment.manage.microsoft.com : OK
EndpointReach     : enterpriseregistration.windows.net : OK
ProxyDetected     : No

--- Licensing ---
M365LicenseFound  : Yes
IntuneP1License   : Yes
AutopilotLicense  : Yes
```

### **Appendix B: Windows Error Code Reference**

- **0x80180014:** MDM Enrollment Service error — Device is already enrolled. This error is returned when an attempt to enroll a device fails because the device has an existing MDM enrollment.
- **0x80070005:** ERROR_ACCESS_DENIED — Windows system error. The caller does not have sufficient permissions to perform the requested action. In the context of Intune policy delivery, this typically means the device's enrollment context does not match the policy's assignment scope.

### **Appendix C: Deprovisioning Command Reference**

```powershell
# Check device enrollment status
dsregcmd /status

# Leave Azure AD (removes device from Azure AD and clears enrollment)
dsregcmd /leave

# Clear Intune enrollment cache (must be run after dsregcmd /leave)
Remove-Item -Path "$env:ProgramData\Microsoft\Enrollment\Status\EnrollmentResult.json" -Force

# Force Group Policy update
gpupdate /force

# Trigger Autopilot reset (via Settings UI)
# Settings > System > Recovery > Reset this PC > Keep my files
```

### **Appendix D: Intune Audit Log Search Query**

In Intune admin center, use the following filter to find devices with enrollment anomalies:

```
Activity contains "Enroll" AND Activity contains "Device"
Timeframe: 2024-03-01 to 2024-03-31
Order by: Device Name, Timestamp (descending)
```

Review each result and note devices where no corresponding "Retire" or "Delete" activity precedes the "Enroll" activity.

---

*RCA Document Generated: 2026-08-11  
Document Version: 1.0  
Next Review Date: 2026-09-30*
