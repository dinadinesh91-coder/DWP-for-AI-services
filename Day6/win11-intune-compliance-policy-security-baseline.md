# Windows 11 Intune Compliance Policy — Security Baseline Translation

**Author:** DWP Engineer  
**Date:** 2026-08-11  
**Scope:** Windows 11 devices managed via Microsoft Intune  
**Grace Period:** 7 days applied to all settings  

---

## How to Apply Grace Period

In Intune, each compliance policy has a **"Mark device noncompliant"** schedule. Set this to **7 days** for all settings below.

**UI Path:**  
`Intune admin center > Devices > Manage devices > Compliance > [Policy Name] > Properties > Actions for noncompliance > Mark device noncompliant: 7 days`

---

## Requirement 1 — BitLocker Must Be Enabled on the OS Drive

| Field | Detail |
|---|---|
| **Setting Name** | Require BitLocker |
| **Value** | Require |
| **UI Path** | `Intune admin center > Devices > Manage devices > Compliance > + Create policy > Platform: Windows 10 and later > Profile type: Windows 10/11 compliance policy > Compliance settings > System Security > Require BitLocker` |

**Effect:**  
Intune queries the device's BitLocker status via the Windows Health Attestation Service (HAS). The device is only marked compliant if the OS drive is encrypted and BitLocker is reporting as active.

**False-Positive Risk:**  
- BitLocker provisioned but encryption still **in progress** — HAS reports non-compliant until encryption is 100% complete. Common on newly enrolled or freshly imaged devices.  
- Devices where BitLocker is managed via **Group Policy** rather than Intune may not report status correctly to HAS.  
- Suspended BitLocker (e.g. during a firmware/BIOS update) will flag as non-compliant until resumed.  
- Virtual machines without a TPM chip may not support BitLocker and will always flag.

**Recommendation:**  
Apply the 7-day grace period to allow encryption to complete post-enrolment. Exclude known VM collections via a separate compliance policy or dynamic device group. Ensure any GPO-based BitLocker deployments are reporting to HAS.

---

## Requirement 2 — Secure Boot Must Be Enabled

| Field | Detail |
|---|---|
| **Setting Name** | Require Secure Boot to be enabled on the device |
| **Value** | Require |
| **UI Path** | `Intune admin center > Devices > Manage devices > Compliance > + Create policy > Platform: Windows 10 and later > Profile type: Windows 10/11 compliance policy > Compliance settings > Device Health > Require Secure Boot to be enabled on the device` |

**Effect:**  
Intune checks via the Health Attestation Service that Secure Boot is active in firmware. This ensures only trusted, signed bootloaders and OS components can initialise — protecting against boot-level malware and rootkits.

**False-Positive Risk:**  
- Legacy BIOS (non-UEFI) hardware cannot support Secure Boot and will always be non-compliant.  
- Some older Lenovo/Dell models have Secure Boot present but disabled by default in firmware — requires manual BIOS intervention.  
- Dual-boot Linux configurations often require Secure Boot to be disabled.  
- Some third-party disk encryption tools (non-BitLocker) are incompatible with Secure Boot.

**Recommendation:**  
Exclude any legacy BIOS hardware via a dynamic group (filter on `deviceModel` or `operatingSystemVersion`). For dual-boot devices, assess whether they should be in scope for compliance at all. Do not weaken this setting; it is a critical control.

> **⚠ UI Path Note:** As of recent Intune updates (2024+), the Device Health section has been reorganised in some tenants. If you do not see this under **Device Health**, check under **Windows Health Attestation Service** within the same policy. Verify current path in your tenant before deploying.

---

## Requirement 3 — Minimum OS Build: N-1 (22621.2861)

| Field | Detail |
|---|---|
| **Setting Name** | Minimum OS version |
| **Value** | `10.0.22621.2861` |
| **UI Path** | `Intune admin center > Devices > Manage devices > Compliance > + Create policy > Platform: Windows 10 and later > Profile type: Windows 10/11 compliance policy > Compliance settings > Device Properties > Minimum OS version` |

**Effect:**  
Devices running a build older than `10.0.22621.2861` (Windows 11 22H2, N-1 relative to the latest known-good `22621.3155`) will be flagged as non-compliant. This ensures devices are within one patch cycle of current and have received critical security patches.

**Current Baseline Reference:**

| Label | Build |
|---|---|
| Latest known-good (N) | `10.0.22621.3155` |
| Minimum accepted (N-1) | `10.0.22621.2861` |

**False-Positive Risk:**  
- Devices mid-way through a **Windows Update scan cycle** that have not yet downloaded or applied the latest patch will flag until the update installs and the device reboots.  
- Devices on **Windows Update for Business (WUfB) deferral rings** (e.g. Pilot/Broad rings) may legitimately be on an older build within policy but still flag this compliance check.  
- Devices that have **update paused** by the user or by a policy will fall behind quickly.

**Recommendation:**  
Align this minimum build value with your slowest WUfB deferral ring. If your Broad ring defers by 14 days, ensure N-1 corresponds to a build that is at least 14 days old. Review and update this value with each Patch Tuesday cycle. Use a naming convention in the policy name to capture the review date (e.g. `WIN11-COMPLIANCE-2026-08`).

> **⚠ UI Path Note:** Intune requires the full four-part version string (e.g. `10.0.22621.2861`). Entering only `22621.2861` will be rejected. Confirm the field format in your tenant — some versions of the UI label this as **"OS build"** rather than **"OS version"**.

---

## Requirement 4 — Windows Defender Real-Time Protection Must Be On

| Field | Detail |
|---|---|
| **Setting Name** | Require real-time protection |
| **Value** | Require |
| **UI Path** | `Intune admin center > Devices > Manage devices > Compliance > + Create policy > Platform: Windows 10 and later > Profile type: Windows 10/11 compliance policy > Compliance settings > System Security > Microsoft Defender Antimalware > Require real-time protection` |

**Effect:**  
Checks that Windows Defender's real-time protection component is active and not disabled. Devices with RTP turned off — whether by user action, script, or conflicting third-party AV — will be marked non-compliant.

**False-Positive Risk:**  
- **Third-party antivirus** (e.g. CrowdStrike, Sophos, Trend Micro) registered with Windows Security Center as the active AV provider may cause Defender RTP to be in a "passive mode" or disabled state — this can flag as non-compliant even though the device is protected.  
- Temporary disablement during software installation (e.g. some legacy installers require AV to be off).  
- Defender service delays on startup before the compliance check runs.

**Recommendation:**  
If your organisation uses a third-party AV as the primary solution, ensure it is registered correctly with the Windows Security Center API so Intune recognises it. If Defender is in passive mode by design alongside another AV, consider whether this control applies — you may need a separate compliance policy variant for devices with third-party AV. Do not disable this requirement entirely.

---

## Requirement 5 — Firewall Must Be Enabled for All Profiles

| Field | Detail |
|---|---|
| **Setting Name** | Microsoft Defender Firewall |
| **Value** | Require |
| **UI Path** | `Intune admin center > Devices > Manage devices > Compliance > + Create policy > Platform: Windows 10 and later > Profile type: Windows 10/11 compliance policy > Compliance settings > System Security > Microsoft Defender Firewall` |

**Effect:**  
Verifies that Windows Firewall is active across all three network profiles: **Domain**, **Private**, and **Public**. All three must be enabled for the device to pass this check.

**False-Positive Risk:**  
- Third-party firewall software (e.g. Palo Alto GlobalProtect host firewall) may disable Windows Firewall — device will flag as non-compliant even if an equivalent control is in place.  
- GPO or legacy scripts that disable Windows Firewall for "compatibility" reasons on older applications.  
- Firewall briefly disabled during certain network driver or VPN client updates.

**Recommendation:**  
Audit for any GPO or scripts that disable Windows Firewall. If a third-party firewall is in use, verify whether Intune's check queries Windows Security Center (which may show the third-party product) or queries the Windows Firewall service directly. Raise a change to re-enable Windows Firewall for all profiles and run third-party firewalls alongside it where compatible.

> **⚠ UI Path Note:** In some Intune builds the setting is listed as **"Windows Firewall"** rather than **"Microsoft Defender Firewall"** in the UI. The underlying MDM CSP (`./Vendor/MSFT/Firewall`) is consistent, but verify the label in your tenant.

---

## Requirement 6 — A PIN or Password Must Be Configured

| Field | Detail |
|---|---|
| **Setting Name** | Require a password to unlock mobile devices / Password required |
| **Value** | Require |
| **Minimum password length** | 8 (recommended baseline) |
| **UI Path** | `Intune admin center > Devices > Manage devices > Compliance > + Create policy > Platform: Windows 10 and later > Profile type: Windows 10/11 compliance policy > Compliance settings > System Security > Password > Require a password to unlock mobile devices` |

**Effect:**  
Ensures the device has a local or domain password, or a Windows Hello for Business PIN, configured. Devices with no screen lock or password will be marked non-compliant. When combined with Conditional Access, this blocks access to Microsoft 365 services from unlocked/unprotected devices.

**False-Positive Risk:**  
- **Shared/kiosk devices** configured intentionally with auto-logon and no password (e.g. reception terminals, print kiosks) will always flag.  
- Windows Hello for Business PIN may not be recognised in some edge cases if WHfB provisioning is incomplete.  
- Domain-joined devices where the password policy is enforced by GPO rather than Intune MDM may report an inconsistent state.

**Recommendation:**  
Exclude kiosk and shared devices from this compliance policy and apply a dedicated **kiosk compliance policy** appropriate to their use case. Ensure Windows Hello for Business provisioning is completing successfully before this policy applies — the 7-day grace period assists here. Set minimum password length to 8 characters as a minimum; consider 12+ for privileged accounts via a separate policy.

> **⚠ UI Path Note:** The "Require a password to unlock mobile devices" label is inherited from the mobile device management origin of Intune and applies equally to Windows PCs. In newer Intune admin center versions (2024+) this section may be labelled simply **"Password"** with individual sub-settings. Confirm in your tenant.

---

## Requirement 7 — Device Must Not Be Jailbroken or Rooted

| Field | Detail |
|---|---|
| **Setting Name** | Block jailbroken devices |
| **Value** | Block |
| **UI Path** | `Intune admin center > Devices > Manage devices > Compliance > + Create policy > Platform: Windows 10 and later > Profile type: Windows 10/11 compliance policy > Compliance settings > Device Health > Block jailbroken devices` |

**Effect:**  
On Windows, this setting works in conjunction with the Health Attestation Service to detect signs of integrity violations — such as a compromised bootloader, test-signing mode enabled, or code integrity violations — that are analogous to a "rooted" state on mobile. Devices that fail attestation are blocked.

**False-Positive Risk:**  
- Developer devices with **test signing enabled** (e.g. `bcdedit /set testsigning on`) will fail this check — legitimate for developers but flagged as compromised.  
- Devices running **unsigned or self-signed drivers** for niche hardware (e.g. specialist peripherals, lab equipment) may fail code integrity checks.  
- HAS connectivity issues (network proxy, firewall blocking HAS endpoints) can cause attestation to fail, marking a healthy device as non-compliant.

**Recommendation:**  
Exclude developer workstations from the standard compliance policy and apply a separate, appropriately scoped developer compliance policy. Ensure HAS endpoints (`has.spserv.microsoft.com`) are reachable through your proxy/firewall. Do not weaken or remove this control for standard user devices.

> **⚠ UI Path Note:** For Windows 10/11, the "jailbroken" terminology maps to Windows Health Attestation integrity checks. This is distinct from the iOS/Android jailbreak detection. In some Intune tenants this setting may not be separately surfaced for Windows — the equivalent protection is delivered via the Secure Boot and BitLocker HAS checks above. Verify this setting is visible and applicable in your tenant's Windows compliance policy template.

---

## Grace Period Summary

| Requirement | Setting | Grace Period |
|---|---|---|
| BitLocker on OS drive | Require BitLocker | 7 days |
| Secure Boot enabled | Require Secure Boot | 7 days |
| Minimum OS build 22621.2861 | Minimum OS version | 7 days |
| Defender real-time protection | Require real-time protection | 7 days |
| Firewall all profiles | Microsoft Defender Firewall | 7 days |
| PIN or password configured | Require a password | 7 days |
| Not jailbroken/rooted | Block jailbroken devices | 7 days |

---

## Settings Requiring UI Path Verification

The following settings have known UI label or path changes since training data and **must be verified in your Intune tenant before deployment**:

| # | Setting | Risk |
|---|---|---|
| 2 | Secure Boot — location may have moved from Device Health to Windows Health Attestation Service section | Medium |
| 3 | Minimum OS version — field format must be full four-part string `10.0.xxxxx.xxxx` | Low (data entry) |
| 5 | Firewall — label may read "Windows Firewall" vs "Microsoft Defender Firewall" | Low |
| 6 | Password section — may be reorganised under a "Password" heading rather than "Require a password to unlock mobile devices" | Low |
| 7 | Block jailbroken devices — may not be separately surfaced for Windows; covered by HAS checks in some tenant versions | High — verify before relying on this setting |

---

## Recommended Deployment Steps

1. Navigate to **Intune admin center > Devices > Manage devices > Compliance > + Create policy**. Set **Platform** to `Windows 10 and later` and **Profile type** to `Windows 10/11 compliance policy`, then click **Create**.
2. Apply all settings above.
3. Set **"Mark device noncompliant"** action to **7 days** for all settings.
4. Assign to a **pilot group** (10–20 devices) first and monitor the **Device compliance** report for 48 hours before broad deployment.
5. Pair this compliance policy with a **Conditional Access policy** that blocks access to Microsoft 365 when compliance state is non-compliant (after grace period expires).
6. Schedule a **monthly review** of the minimum OS build value to keep pace with Patch Tuesday releases.

---

## Validation Steps After Assignment

1. Open **Intune admin center > Devices > All devices > [target device] > Device compliance** to see the device's status for this policy.
2. In that device view, select the compliance policy entry to confirm which requirement is failing or in grace period.
3. Use **Devices > Compliance policies > [policy name] > Device status** to review fleet-wide results for the same policy.
4. If the device is used with Conditional Access, confirm the sign-in result in **Microsoft Entra admin center > Sign-in logs** to see whether access is being allowed, blocked, or deferred by grace period.

### Compliance Status Meaning

| Status | Meaning | Conditional Access Impact |
|---|---|---|
| **Compliant** | The device satisfies the policy requirements. | Access is allowed, assuming no other Conditional Access controls block it. |
| **Not compliant** | The device failed at least one required setting and the grace period has expired or is not configured for that item. | Access is blocked by Conditional Access if the policy requires compliant devices. |
| **In grace period** | The device has failed a requirement, but the noncompliance timer has not yet expired. | Access is usually still allowed until the grace period ends, then it becomes blocked if the device remains non-compliant. |

### BitLocker False Positive Triage

If BitLocker shows **non-compliant** even though encryption is enabled, check these first:

1. **Encryption not fully finished** - Fastest check: run `manage-bde -status C:` and confirm the OS drive shows **Percentage Encrypted: 100%** and **Protection Status: Protection On**.
2. **BitLocker is suspended** - Fastest check: run `manage-bde -status C:` and look for **Protection Status: Protection Off** or a suspended state after BIOS/firmware work.
3. **Device is not reporting cleanly to Intune / HAS** - Fastest check: in the Intune device record, open the compliance details and confirm the last check-in time; then verify the device can reach the Health Attestation path used by your tenant and that the policy is not still inside the grace window.

### First 24 Hours Monitoring

1. Watch the **policy device status** page for a spike in **Not compliant** devices immediately after assignment.
2. Filter failures by **BitLocker** to see whether the issue is isolated to encryption state or is fleet-wide.
3. Compare the failed devices against enrollment age, reboot state, and recent firmware/BIOS activity.
4. Check **Sign-in logs** for Conditional Access failures tied to the same policy to confirm user impact.
5. Recheck the same sample after 4, 8, and 24 hours to confirm devices are moving from non-compliant to compliant instead of staying stuck.

---

*Document generated: 2026-08-11 | Review due: 2026-09-11*
