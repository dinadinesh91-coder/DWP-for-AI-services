# Adding a Windows Application to the Intune App Catalog

**Role:** DWP Engineer  
**Purpose:** Step-by-step guide for adding a Windows app to the Microsoft Intune app catalog, required before any phased rollout can begin.  
**Worked example throughout:** FinBridge Connect v3.1 — a Windows LOB app packaged as a `.intunewin` file.

> **Tenant version warning:** Microsoft Intune's admin portal is updated continuously. Exact menu labels, button names, and navigation paths **will vary between tenant versions**. Every label given in this guide reflects a common layout at time of writing. **Always verify against your live tenant** before assuming a label or path is correct. Do not raise an incident if a label differs — locate the nearest equivalent option and proceed.

---

## Prerequisites

Before starting, confirm you have:

- [ ] Global Administrator or Intune Administrator role assigned in Entra ID
- [ ] The `.intunewin` package file for the application ready and accessible
- [ ] The install and uninstall command strings confirmed with the application owner
- [ ] A pilot/test device group already created in Entra ID (see Step 6)
- [ ] The target minimum OS version and architecture confirmed

---

## Step 1 — Navigate to the Intune App Catalog

1. Open a browser and go to: **https://intune.microsoft.com**
2. Sign in with your DWP administrator credentials.
3. In the left-hand navigation pane, select **Apps**.

   > **Tenant version note:** This pane may be labelled **"Apps"**, **"Client apps"**, or nested under a **"Devices"** or **"Endpoint"** section depending on your portal version. Verify the label in your tenant.

4. Under **Apps**, select **All apps**.
5. Select **+ Add** (top-left of the app list).

   A **"Select app type"** panel will appear on the right side of the screen.

---

## Step 2 — Select the Correct App Type

Choosing the wrong app type is the most common early mistake. Use the table below to select the correct type for your scenario.

| Scenario | App type to select |
|---|---|
| Windows LOB app packaged as a `.intunewin` file | **Windows app (Win32)** |
| App available in the Microsoft Store | **Microsoft Store app (new)** *(label may vary — look for Store integration option)* |
| Web-based tool or SaaS shortcut | **Web link** |

**For FinBridge Connect v3.1:**

1. In the **"Select app type"** panel, expand the **"Other"** section (or scroll to find **"Windows app (Win32)"**).

   > **Tenant version note:** The grouping of app types (e.g., "Store app", "Other", "Line-of-business app") varies. If you cannot find **Windows app (Win32)**, look for **"Win32"** as a standalone entry or under an **"Other"** or **"Windows"** heading.

2. Select **Windows app (Win32)**.
3. Select **Select** to confirm.

---

## Step 3 — Upload the App Package

1. On the **App package file** screen, select **Select file**.
2. Browse to and select the `.intunewin` file for FinBridge Connect v3.1.
3. Wait for the upload to complete. A green tick or "Uploaded" confirmation should appear.
4. Select **OK** or **Next** to continue.

   > Do not close the browser tab during upload. Large packages may take several minutes.

---

## Step 4 — Complete App Information

This section defines how the app appears in the Intune portal and, if made available to users, in the Company Portal.

Navigate to the **App information** tab (the wizard will advance you there automatically after upload).

Fill in each required field as follows:

| Field | Required | FinBridge Connect v3.1 value |
|---|---|---|
| **Name** | Yes | `FinBridge Connect` |
| **Description** | Yes | `FinBridge Connect v3.1 — financial bridging integration client. Managed deployment. Contact the Service Desk for support.` |
| **Publisher** | Yes | `FinBridge Ltd` |
| **App version** | Recommended | `3.1` |
| **Category** | Optional | Select the most appropriate category (e.g., *Business*, *Productivity*). Leave blank if unsure. |
| **Information URL** | Optional | Leave blank unless you have an internal knowledge base article URL. |
| **Privacy URL** | Optional | Leave blank unless required by your organisation's policy. |
| **Developer** | Optional | Leave blank. |
| **Owner** | Optional | Enter the name of the application owner or service team (e.g., `Finance Applications Team`). |
| **Notes** | Optional | `Deployed as part of FinBridge rollout — pilot phase. Approved by Change Advisory Board.` |
| **Logo** | Optional | Upload the FinBridge Connect logo if available. This appears in the Company Portal. |

Select **Next** when all required fields are complete.

---

## Step 5 — Configure Program (Install and Uninstall Commands)

The **Program** tab defines how Intune installs and removes the app, and in which context it runs.

> **Tenant version note:** This tab may be labelled **"Program"** or **"Install experience"** depending on your portal version. Verify in your tenant.

### 5.1 Install command

Enter the exact install command string:

```
FinBridgeConnect_Setup.exe /silent
```

> Do not add quotes around the command unless the path contains spaces. The `.intunewin` package root is the working directory at runtime.

### 5.2 Uninstall command

Enter the exact uninstall command string:

```
FinBridgeConnect_Setup.exe /uninstall /silent
```

### 5.3 Install behavior

This controls whether the installer runs as **SYSTEM** or as the **logged-in user**.

| Option | When to use |
|---|---|
| **System** | The app installs for all users on the device, requires admin rights, or writes to `HKLM` registry keys. Use this for most LOB apps. |
| **User** | The app installs only for the currently logged-in user, writes to `HKCU`, and does not require elevation. |

**For FinBridge Connect v3.1:** Select **System** (the detection key targets `HKLM`, indicating a machine-wide install).

### 5.4 Device restart behavior

Select **Determine behavior based on return codes** unless the application owner has confirmed a specific restart requirement.

Select **Next** when complete.

---

## Step 6 — Set Requirements

The **Requirements** tab prevents Intune from attempting to install the app on devices that do not meet minimum criteria.

> **Tenant version note:** Field names and available options on this tab may vary. Verify each setting label against your live tenant.

| Field | Required | FinBridge Connect v3.1 value |
|---|---|---|
| **Operating system architecture** | Yes | Select **64-bit** (and **32-bit** only if the app explicitly supports it — confirm with the application owner) |
| **Minimum operating system** | Yes | Select **Windows 10 21H2** or the minimum version confirmed by the application owner. Do not select a version lower than your organisation's supported baseline. |

Leave all other requirement fields at their defaults unless the application owner has specified additional constraints (e.g., minimum disk space, minimum RAM).

Select **Next** when complete.

---

## Step 7 — Configure Detection Rules

Detection rules tell Intune how to determine whether the application has successfully installed on a device. Without a correct detection rule, Intune will report install failures even when the app is present.

> **Tenant version note:** The layout of this tab and the names of detection rule types may vary. Look for a **"+ Add"** or **"Add rule"** option and verify the available rule types against your tenant.

### Detection rule types available

| Rule type | Use when |
|---|---|
| **Registry** | The app writes a known key or value to the registry on install. This is the most reliable method for LOB apps. |
| **MSI product code** | The app is an MSI and you have the product GUID from `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall`. |
| **File or folder** | No registry key exists — detect by presence of a specific file (e.g., the main executable). |
| **Script** | Complex logic is required (e.g., version comparison). Use only when simpler rule types are insufficient. |

### 7.1 Adding a Registry detection rule for FinBridge Connect v3.1

1. Select **+ Add** (or **"Add rule"** — label may vary).
2. Set **Rule type** to **Registry**.
3. Complete the fields as follows:

   | Field | Value |
   |---|---|
   | **Key path** | `HKEY_LOCAL_MACHINE\SOFTWARE\FinBridge\Connect` |
   | **Value name** | `Version` |
   | **Detection method** | **String comparison** |
   | **Operator** | **Equals** |
   | **Value** | `3.1` |
   | **Associated with a 32-bit app on 64-bit clients** | Leave **unchecked** unless the app is explicitly 32-bit |

4. Select **OK** to save the rule.
5. Confirm the rule appears in the detection rules list.

Select **Next** when complete.

---

## Step 8 — Review Return Codes

Return codes tell Intune how to interpret the exit code the installer returns when it finishes. Incorrect return codes cause Intune to report false failures or miss required reboots.

> **Tenant version note:** This tab may be labelled **"Return codes"** or **"Exit codes"**. Verify in your tenant.

The default return codes pre-populated by Intune cover the majority of standard Windows installers:

| Return code | Type | Meaning |
|---|---|---|
| `0` | Success | Install completed successfully, no reboot required. |
| `1707` | Success | Install completed successfully (MSI). |
| `3010` | Soft reboot | Install completed successfully, reboot required but not forced. |
| `1641` | Hard reboot | Install completed successfully, reboot was initiated. |
| `1618` | Retry | Another install is in progress — Intune will retry. |

**For FinBridge Connect v3.1:** Do not modify the default return codes unless the application owner has provided a specific exit code reference. If the installer returns a non-standard success code (e.g., `2`), add it here with type **Success**.

Select **Next** when complete.

---

## Step 9 — Review the App and Save

1. On the **Review + create** (or **"Review + save"**) tab, read through all configured values.
2. Verify the following before saving:

   - [ ] Name and version are correct
   - [ ] Install and uninstall commands match exactly what was specified
   - [ ] Install behavior is set to **System**
   - [ ] Detection rule key path and value are correct
   - [ ] No required fields show a validation error

3. Select **Create** (or **Save** — label may vary).

Intune will process and publish the app. This may take 1–5 minutes. Do not navigate away until the portal confirms the app has been created.

---

## Step 10 — Assign the App to a Pilot Group

> **Why a pilot group and not the full fleet?**  
> Assigning a new app directly to all 10,000 devices simultaneously means any misconfiguration — wrong install command, broken detection rule, incompatible OS version — is immediately amplified across the entire estate. A pilot group of 10–25 devices limits blast radius to a small, monitored set, allows you to verify real-world behaviour before widening scope, and is required by DWP change management policy for new software deployments.

### Assignment types explained

| Assignment type | Behaviour |
|---|---|
| **Required** | Intune installs the app automatically on all assigned devices/users. The end user is not asked for consent. |
| **Available for enrolled devices** | The app appears in the Company Portal. The user may choose to install it. Intune does not install it automatically. |
| **Uninstall** | Intune removes the app from all assigned devices/users. |

### 10.1 Add a Required assignment to the pilot group

1. On the app's overview page, select **Properties** (left-hand menu), then scroll to **Assignments** and select **Edit**.

   > **Tenant version note:** Assignments may be accessible during the initial creation wizard (as a tab) or only after creation via the **Properties** or **Assignments** menu item. Verify in your tenant.

2. Under **Required**, select **+ Add group**.
3. Search for and select your pre-created pilot device group (e.g., `SG-Intune-Pilot-FinBridge` or your organisation's equivalent).
4. Select **Select** to confirm.
5. Select **Review + save**, then **Save**.

   > **Do not add the full device group or "All Devices" at this stage.** Full fleet assignment must only occur after pilot results have been reviewed and signed off.

---

## Step 11 — Verify the App Appears Correctly in the Catalog

1. In the Intune portal, navigate to **Apps > All apps**.
2. Search for **FinBridge Connect** in the search bar.
3. Confirm the app appears in the list with:
   - Correct name and publisher
   - App type shown as **Win32** (or **Windows app (Win32)**)
   - A status of **Published** or equivalent (not **Failed** or **Error**)

If the app does not appear or shows an error status, select the app entry and review the **Device install status** and any error messages displayed in the overview panel.

---

## Step 12 — Check Install Status on an Assigned Test Device

Allow up to **8 hours** for Intune policy to reach the pilot device in normal conditions. To trigger an immediate sync on the test device:

1. On the test device, open **Settings > Accounts > Access work or school**.
2. Select the work account, then select **Info**.
3. Scroll down and select **Sync** (label may vary by Windows version).

Alternatively, open an elevated PowerShell prompt and run:

```powershell
Start-Process -FilePath "C:\Program Files (x86)\Microsoft Intune Management Extension\Microsoft.Management.Services.IntuneWindowsAgent.exe" -ArgumentList "/SyncSession"
```

> **Tenant version note:** The Intune Management Extension path may differ on your devices. Verify the executable location if the command above fails.

### 12.1 Check status in the Intune portal

1. Navigate to **Apps > All apps > FinBridge Connect**.
2. Select **Device install status** from the left-hand menu (label may vary).
3. Locate the pilot test device by name.
4. Review the status column.

---

## Step 13 — Interpret Install Status Values

| Status | Meaning | Action required |
|---|---|---|
| **Installed** | The detection rule was satisfied. The app is present and correctly detected on the device. | None — proceed to monitor the remaining pilot devices. |
| **Failed** | The installer ran but returned a non-success exit code, or the detection rule was not satisfied after install. | Select the device entry to view the error code. Cross-reference with Step 8 return codes. Check the Intune Management Extension log on the device: `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log` |
| **Not applicable** | The device did not meet one or more requirements defined in Step 6 (e.g., wrong OS version or architecture). | Review Step 6 requirements. Confirm the pilot device meets the minimum OS version selected. |
| **Pending** | Intune has not yet attempted install on the device. Policy may not have synced yet. | Wait and re-check after triggering a manual sync (Step 12). If still pending after 24 hours, investigate device connectivity to Intune. |
| **Not installed** | The device is in scope but install has not started. | Same as Pending — verify sync and device check-in status. |

---

## Post-Pilot Checklist Before Full Fleet Rollout

Do not widen the assignment to the full device fleet until all of the following are confirmed:

- [ ] All pilot devices show status **Installed**
- [ ] No pilot devices show status **Failed** without a documented, resolved root cause
- [ ] At least one end user on a pilot device has confirmed the application launches and functions correctly
- [ ] A Change Advisory Board approval for the wider rollout has been obtained (if required by DWP change management policy)
- [ ] The uninstall command has been validated on at least one pilot device

---

## Quick Reference — FinBridge Connect v3.1 Configuration Summary

| Setting | Value |
|---|---|
| App type | Windows app (Win32) |
| Name | FinBridge Connect |
| Publisher | FinBridge Ltd |
| Version | 3.1 |
| Install command | `FinBridgeConnect_Setup.exe /silent` |
| Uninstall command | `FinBridgeConnect_Setup.exe /uninstall /silent` |
| Install behavior | System |
| Min OS version | Windows 10 21H2 (confirm with app owner) |
| Architecture | 64-bit |
| Detection — rule type | Registry |
| Detection — key path | `HKEY_LOCAL_MACHINE\SOFTWARE\FinBridge\Connect` |
| Detection — value name | `Version` |
| Detection — method | String comparison — Equals — `3.1` |
| Initial assignment | Required — pilot group only |

---

*Document owner: DWP Engineering | Review cycle: Review when Intune portal layout changes or annually, whichever is sooner.*
