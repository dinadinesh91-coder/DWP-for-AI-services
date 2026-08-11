# KB: AVD Black Screen After Login (POOL-FIN-01)

Version header: v 1.0, 07/08/2026, status : Draft

## Background
POOL-FIN-01 is the Finance Azure Virtual Desktop host pool used for production user desktops. Session hosts are delivered from a VM scale set image, so one bad image change can affect many users at once. This incident matters because users can authenticate successfully and still fail to reach a usable desktop, which looks like a generic AVD outage unless the engineer checks the host-pool split, image version, and host-side render path.

POOL-FIN-02 is the comparison pool for this incident. It remained healthy and is the control group that proves the issue is not a tenant-wide Azure Virtual Desktop platform failure.

## Symptom
What the engineer observes:
- A spike of successful sign-ins followed by unusable sessions in POOL-FIN-01.
- Session hosts in POOL-FIN-01 remain reachable and usually show Available in Azure Virtual Desktop.
- POOL-FIN-02 continues to accept normal user sessions during the same time window.
- The issue starts after the 02:00 image update wave and is reported from about 07:00 onward.

What the user reports:
- The user can sign in to AVD, but the desktop stays black.
- For some users the black screen clears after about 30 seconds.
- For other users the black screen persists until they disconnect.
- User data is intact; the failure is in desktop rendering after sign-in, not account authentication.

## Root Cause
Specific technical cause:
- A graphics driver regression was introduced by the 02:00 overnight image update applied to POOL-FIN-01 session hosts.

Evidence that confirms it:
- Change isolation: POOL-FIN-01 received the overnight image update; POOL-FIN-02 did not.
- Scope isolation: about 40% of Finance users on POOL-FIN-01 were affected; POOL-FIN-02 was unaffected.
- Timing isolation: the symptom started after the image update window, not before it.
- Recovery proof: service returned to normal only after the image-focused corrective action was applied to POOL-FIN-01.
- Supporting host evidence: affected hosts can show render-path disruption in Windows System log event data after user logon, while authentication and session creation events still complete.

Important diagnostic note:
- This incident does not have one unique Azure Virtual Desktop broker error code that proves the case by itself. Confirmation comes from the combination of pool comparison, image comparison, host-side render evidence, and successful rollback canary outcome.

## Detection
Confirm all mandatory checks below before changing the image. Treat POOL-FIN-02 as the control group in every comparison.

### 1. Confirm the symptom is pool-specific in Log Analytics
Portal path:
- Azure Portal > Azure Monitor > Logs > <AVD Log Analytics Workspace>

Log/table:
- WVDConnections

Fields to inspect:
- HostPoolName
- UserName
- SessionHostName
- ConnectionState
- CorrelationId
- TimeGenerated

Query:
```kusto
WVDConnections
| where TimeGenerated between (ago(6h) .. now())
| where HostPoolName in~ ("POOL-FIN-01", "POOL-FIN-02")
| project TimeGenerated, HostPoolName, UserName, SessionHostName, ConnectionState, CorrelationId
| order by TimeGenerated desc
```

What to look for:
- POOL-FIN-01 shows the affected users connecting in the incident window.
- POOL-FIN-02 shows normal connected sessions in the same period.
- The pool split must be clear: impacted users are concentrated in POOL-FIN-01, not across both pools.

### 2. Check for broker or agent errors, but do not use them as the sole decision point
Portal path:
- Azure Portal > Azure Monitor > Logs > <AVD Log Analytics Workspace>

Log/table:
- WVDErrors

Fields to inspect:
- HostPoolName
- UserName
- SessionHostName
- Code
- Message
- CorrelationId
- TimeGenerated

Query:
```kusto
WVDErrors
| where TimeGenerated between (ago(6h) .. now())
| where HostPoolName in~ ("POOL-FIN-01", "POOL-FIN-02")
| project TimeGenerated, HostPoolName, UserName, SessionHostName, Code, Message, CorrelationId
| order by TimeGenerated desc
```

What to look for:
- POOL-FIN-01 may show session-related errors or retries during the affected window.
- POOL-FIN-02 should not show a matching spike for the same users or time range.
- If both pools show the same error pattern, stop and investigate a shared service issue instead of this KB.

### 3. Confirm session creation completed on an affected host
Portal path:
- Azure Portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > <affected-host> > Virtual machine

Host log location:
- Event Viewer > Applications and Services Logs > Microsoft > Windows > TerminalServices-LocalSessionManager > Operational

Event IDs to inspect:
- Event ID 21
- Event ID 22
- Event ID 24

Fields to inspect in each event:
- Date and Time
- User
- Session ID
- Address
- EventData text around shell start or disconnect timing

What to look for:
- Event ID 21 around the user-reported sign-in time confirms session logon succeeded.
- Event ID 22 shortly after Event ID 21 confirms the shell-start notification path was reached.
- Event ID 24 soon after Event ID 21 or 22 is supporting evidence when users disconnect because the desktop never becomes usable.

Interpretation:
- If Event ID 21 and Event ID 22 exist but the user still sees a black screen, the failure is after authentication and during desktop rendering or shell presentation.

### 4. Check for host-side graphics reset evidence
Portal path:
- Azure Portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > <affected-host> > Virtual machine

Host log location:
- Event Viewer > Windows Logs > System

Event IDs to inspect:
- Event ID 4101 from source Display

Fields to inspect:
- Logged
- Source
- Event ID
- General message text

What to look for:
- Event ID 4101 near the same timestamp as the failed user logon.
- Message pattern: display driver stopped responding and recovered.

Interpretation:
- Event ID 4101 is strong supporting evidence for this KB because it lines up with a graphics-path regression after image deployment.
- Absence of Event ID 4101 does not fully rule the issue out; the decisive comparison remains the image and pool split.

### 5. Exclude FSLogix profile attach as the primary cause
Portal path:
- Azure Portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > <affected-host> > Virtual machine

Host log location:
- C:\ProgramData\FSLogix\Logs\Profile\<latest-log>.log

Fields or strings to inspect:
- Username
- SID
- VHD or VHDX path
- Status
- ERROR
- Failed

What to look for:
- The user appears in the log for the incident time window.
- Profile attach completes, or at least does not fail in a way that explains the whole symptom.
- There is no repeating attach failure pattern on POOL-FIN-01 that would make this an FSLogix incident instead.

Interpretation:
- If FSLogix shows clean attach activity but the screen remains black, stay on this KB.
- If FSLogix shows hard attach failures for the same users and same hosts, use the FSLogix troubleshooting path instead.

### 6. Compare image state between the bad pool and the healthy control pool
Portal path:
- Azure Portal > Cloud Shell > PowerShell

Commands:
```powershell
az vmss show --resource-group <POOL-FIN-01-VMSS-RG> --name <POOL-FIN-01-VMSS-NAME> --query virtualMachineProfile.storageProfile.imageReference.id -o tsv
az vmss show --resource-group <POOL-FIN-02-VMSS-RG> --name <POOL-FIN-02-VMSS-NAME> --query virtualMachineProfile.storageProfile.imageReference.id -o tsv
```

Fields to inspect:
- virtualMachineProfile.storageProfile.imageReference.id

What to look for:
- POOL-FIN-01 is on the newly deployed image version.
- POOL-FIN-02 is on a different or older known-good image.

Interpretation:
- This is the mandatory comparison check for this incident. If both pools are on the same image and only one pool fails, this KB is not yet proven.

### 7. Final confidence threshold before action
Treat this issue as confirmed when all three conditions are true:
- POOL-FIN-01 is the only affected pool and POOL-FIN-02 is healthy.
- POOL-FIN-01 is on the changed image and POOL-FIN-02 is not.
- Host evidence shows successful session creation with post-logon render failure, with or without System Event ID 4101.

## Resolution
Use the image rollback or corrected image path. Do not reopen POOL-FIN-01 to new sessions until the canary host is proven good.

### 1. Drain the affected pool
Portal path:
- Azure Portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts

Action:
- Set Allow new sessions = No on each affected POOL-FIN-01 session host.

Expected result:
- New user logons stop landing on unstable hosts.

### 2. Move impacted users to the healthy pool
Portal path:
- Azure Portal > Azure Virtual Desktop > Application groups > <POOL-FIN-02-Desktop-App-Group> > Assignments

Action:
- Add affected users or the approved fallback group to the POOL-FIN-02 desktop application group.

Expected result:
- Users can launch a working desktop through POOL-FIN-02 while POOL-FIN-01 is repaired.

### 3. Record the current bad image reference before changing anything
Portal path:
- Azure Portal > Cloud Shell > PowerShell

Action:
```powershell
az vmss show --resource-group <POOL-FIN-01-VMSS-RG> --name <POOL-FIN-01-VMSS-NAME> --query virtualMachineProfile.storageProfile.imageReference.id -o tsv
```

Expected result:
- The exact current image reference ID is captured in the incident ticket as the pre-change value.

### 4. Change the VM scale set model back to the known-good image
Portal path:
- Azure Portal > Cloud Shell > PowerShell

Action:
```powershell
az vmss update --resource-group <POOL-FIN-01-VMSS-RG> --name <POOL-FIN-01-VMSS-NAME> --set virtualMachineProfile.storageProfile.imageReference.id=<KNOWN_GOOD_IMAGE_VERSION_ID>
```

Expected result:
- The VMSS model for POOL-FIN-01 points to the known-good image version.

### 5. Apply the change to one canary instance first
Portal path:
- Azure Portal > Cloud Shell > PowerShell

Action:
```powershell
az vmss update-instances --resource-group <POOL-FIN-01-VMSS-RG> --name <POOL-FIN-01-VMSS-NAME> --instance-ids <CANARY_INSTANCE_ID>
```

Expected result:
- One instance starts applying the corrected VMSS model.

### 6. Wait for the canary instance to finish provisioning
Portal path:
- Azure Portal > Virtual machine scale sets > <POOL-FIN-01-VMSS-NAME> > Instances

Action:
- Open the canary instance and monitor Provisioning state.

Expected result:
- Provisioning state = Succeeded.

### 7. Validate user logon on the canary host
Portal path:
- Azure Portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts

Action:
- Allow a controlled test sign-in to the canary host using an affected user account or approved test account.

Expected result:
- The desktop renders normally and the black-screen symptom does not reproduce.

### 8. Roll the corrected image to the remaining instances
Portal path:
- Azure Portal > Cloud Shell > PowerShell

Action:
```powershell
az vmss update-instances --resource-group <POOL-FIN-01-VMSS-RG> --name <POOL-FIN-01-VMSS-NAME> --instance-ids "*"
```

Expected result:
- All remaining POOL-FIN-01 instances begin applying the corrected image model.

### 9. Confirm all instances completed the rollout
Portal path:
- Azure Portal > Virtual machine scale sets > <POOL-FIN-01-VMSS-NAME> > Instances

Action:
- Review every instance status.

Expected result:
- All targeted instances show Provisioning state = Succeeded.

### 10. Reopen the repaired pool to production sessions
Portal path:
- Azure Portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts

Action:
- Set Allow new sessions = Yes on the remediated hosts.

Expected result:
- POOL-FIN-01 starts accepting new sessions again.

### 11. Remove the temporary fallback routing
Portal path:
- Azure Portal > Azure Virtual Desktop > Application groups > <POOL-FIN-02-Desktop-App-Group> > Assignments

Action:
- Remove the temporary user or group assignment added for the incident.

Expected result:
- Users route back to the standard POOL-FIN-01 access path.

## Verification
### 1. Verify host readiness in Azure Virtual Desktop
Portal path:
- Azure Portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts

Expected result:
- Status = Available
- Allow new sessions = Yes

### 2. Verify successful post-fix connections in Log Analytics
Portal path:
- Azure Portal > Azure Monitor > Logs > <AVD Log Analytics Workspace>

Log/table:
- WVDConnections

Fields to inspect:
- HostPoolName
- ConnectionState
- SessionHostName
- TimeGenerated

Query:
```kusto
WVDConnections
| where TimeGenerated between (ago(30m) .. now())
| where HostPoolName =~ "POOL-FIN-01"
| summarize SuccessfulConnections=count() by SessionHostName, ConnectionState
| order by SuccessfulConnections desc
```

Expected result:
- New sessions in POOL-FIN-01 complete with normal connected state.

### 3. Verify the control pool is no longer carrying incident traffic
Portal path:
- Azure Portal > Azure Monitor > Logs > <AVD Log Analytics Workspace>

Log/table:
- WVDConnections

Fields to inspect:
- HostPoolName
- TimeGenerated

Query:
```kusto
WVDConnections
| where TimeGenerated between (ago(30m) .. now())
| where HostPoolName =~ "POOL-FIN-02"
| summarize FallbackConnections=count() by bin(TimeGenerated, 5m)
| order by TimeGenerated desc
```

Expected result:
- Fallback usage is flat or decreasing after users are moved back.

### 4. Verify host-side session creation without repeat render symptoms
Portal path:
- Azure Portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > <tested-host> > Virtual machine

Host log locations:
- Event Viewer > Applications and Services Logs > Microsoft > Windows > TerminalServices-LocalSessionManager > Operational
- Event Viewer > Windows Logs > System

Event IDs to inspect:
- Event ID 21
- Event ID 22
- Event ID 4101

Expected result:
- New Event ID 21 and Event ID 22 entries exist for the successful validation logon.
- No new Event ID 4101 entries are generated during the successful validation attempt.

### 5. Verify no active fallback assignments remain
Portal path:
- Azure Portal > Azure Virtual Desktop > Application groups > <POOL-FIN-02-Desktop-App-Group> > Assignments

Expected result:
- Temporary incident assignments are removed.

## Rollback
Use rollback immediately if the canary host still shows a black screen, provisioning fails, or the corrected image causes broader instability.

### 1. Stop new sessions landing on the changed hosts
Portal path:
- Azure Portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts

Action:
- Set Allow new sessions = No for all POOL-FIN-01 hosts.

Expected result:
- No additional users are routed onto unstable hosts.

### 2. Re-enable the healthy fallback path
Portal path:
- Azure Portal > Azure Virtual Desktop > Application groups > <POOL-FIN-02-Desktop-App-Group> > Assignments

Action:
- Add currently impacted users back to the POOL-FIN-02 assignment.

Expected result:
- Users can work immediately on the healthy control pool.

### 3. Restore the pre-change image reference on POOL-FIN-01
Portal path:
- Azure Portal > Cloud Shell > PowerShell

Action:
```powershell
az vmss update --resource-group <POOL-FIN-01-VMSS-RG> --name <POOL-FIN-01-VMSS-NAME> --set virtualMachineProfile.storageProfile.imageReference.id=<PRE_CHANGE_IMAGE_ID>
```

Expected result:
- The VMSS model points back to the exact pre-change image recorded earlier.

### 4. Apply the rollback to all POOL-FIN-01 instances
Portal path:
- Azure Portal > Cloud Shell > PowerShell

Action:
```powershell
az vmss update-instances --resource-group <POOL-FIN-01-VMSS-RG> --name <POOL-FIN-01-VMSS-NAME> --instance-ids "*"
```

Expected result:
- All POOL-FIN-01 instances begin moving back to the pre-change image state.

### 5. Confirm rollback traffic is stable on the healthy pool
Portal path:
- Azure Portal > Azure Monitor > Logs > <AVD Log Analytics Workspace>

Log/table:
- WVDConnections

Fields to inspect:
- HostPoolName
- TimeGenerated

Query:
```kusto
WVDConnections
| where TimeGenerated between (ago(15m) .. now())
| where HostPoolName =~ "POOL-FIN-02"
| summarize ActiveFallbackConnections=count() by bin(TimeGenerated, 5m)
| order by TimeGenerated desc
```

Expected result:
- Users continue to connect successfully to POOL-FIN-02 while POOL-FIN-01 is being restored.

## Preventive
Apply all of the following process and tooling changes. Generic advice is not sufficient for this incident class.

1. Split image rollout into named rings.
- Create at least three VMSS rollout rings for AVD images: pilot, finance-canary, production.
- Pilot ring must complete before POOL-FIN-01 is eligible for change.

2. Add a mandatory pool-to-pool image drift check in the release checklist.
- Record the exact value of virtualMachineProfile.storageProfile.imageReference.id for POOL-FIN-01 and POOL-FIN-02 before and after rollout.
- Block production release if the comparison is missing from the change record.

3. Add a post-image automated smoke test for desktop rendering.
- After each image publish, run a scripted login test against one canary host that validates shell render within 60 seconds.
- Store the result with timestamp, session host name, and image ID in the change ticket.

4. Add event capture for the render path.
- Collect and retain TerminalServices-LocalSessionManager Operational events 21, 22, and 24 and System event 4101 for AVD hosts during the first hour after rollout.
- Forward them into the monitoring workspace or the incident evidence store.

5. Gate rollout on a healthy control-pool comparison.
- POOL-FIN-02 must remain on the previous image until POOL-FIN-01 canary validation is complete.
- Do not update both pools in the same maintenance wave for this service.

6. Pre-stage fallback assignment automation.
- Maintain a tested security group or documented assignment script for rapid routing to POOL-FIN-02.
- Review membership rights quarterly so incident responders do not lose the ability to route users during an outage.

## Related
- Day4 analysis hypothesis for this incident.
- Day4 known error record for this incident.
- Day4 closure note for this incident.
- POOL-FIN-02 fallback routing procedure.
- Future KBs covering FSLogix profile attach failure and AVD sign-in failures should be cross-linked because they are close symptom matches but different root causes.
