# L2/L3 KB: AVD Black Screen After Login (POOL-FIN-01)

Version header: v 1.0, 07/08/2026, status : Draft

## Background
POOL-FIN-01 is the Finance Azure Virtual Desktop host pool that delivers production virtual desktops to Finance users. The pool is backed by a VM scale set image, so one bad image deployment can affect multiple session hosts in the same change wave. This incident matters because users authenticate successfully and still receive an unusable desktop, which can be mistaken for a generic Azure Virtual Desktop outage unless the engineer checks host-pool scope, image version, and host-side render evidence.

POOL-FIN-02 is the healthy comparison pool for this incident. It remained stable during the same time window and acts as the control group that rules out a tenant-wide AVD platform failure.

## Symptom
What the engineer observes:
- POOL-FIN-01 receives successful sign-ins followed by unusable user sessions.
- Session hosts in POOL-FIN-01 normally remain in Available state in Azure Virtual Desktop.
- POOL-FIN-02 continues to accept working sessions during the same period.
- The incident begins after the 02:00 image update wave and is first reported around 07:00.

What the user reports:
- Sign-in succeeds, but the desktop stays black.
- For some users the black screen clears after about 30 seconds.
- For other users the screen remains black until they disconnect.
- Files and profile data remain intact; the failure is in desktop render after logon.

## Root Cause
Specific technical cause:
- A graphics driver regression was introduced by the 02:00 overnight image update applied to POOL-FIN-01 session hosts.

Evidence that confirms it:
- POOL-FIN-01 received the image update and POOL-FIN-02 did not.
- About 40% of Finance users on POOL-FIN-01 were impacted, while POOL-FIN-02 remained unaffected.
- The symptom starts after the image update window.
- Service returned to normal only after the image-focused corrective action was applied to POOL-FIN-01.
- Host-side logs can show successful session creation followed by render-path disruption, which is consistent with a graphics-path regression rather than an authentication failure.

Diagnostic note:
- No single AVD broker error code uniquely proves this case. Confirmation depends on the combined evidence of pool comparison, image comparison, host log review, and canary recovery after rollback or corrected image deployment.

## Detection
Use this sequence to confirm the issue in under 3 minutes. Do not start rollback until you have both the failing POOL-FIN-01 evidence and the healthy POOL-FIN-02 control evidence.

### 1. Identify one failing host in POOL-FIN-01 and one healthy control host in POOL-FIN-02
Portal path:
- Azure Portal > Azure Monitor > Logs > <AVD Log Analytics Workspace>

Log/table:
- WVDConnections

Fields to inspect:
- TimeGenerated
- HostPoolName
- UserName
- SessionHostName
- ConnectionState
- CorrelationId

Query:
```kusto
WVDConnections
| where TimeGenerated between (ago(6h) .. now())
| where HostPoolName in~ ("POOL-FIN-01", "POOL-FIN-02")
| project TimeGenerated, HostPoolName, UserName, SessionHostName, ConnectionState, CorrelationId
| order by TimeGenerated desc
```

What to look for:
- Pick one POOL-FIN-01 session host tied to a user who reported the black screen.
- Pick one POOL-FIN-02 session host with a normal successful session in the same time window.
- Use these two hosts for the affected-versus-healthy comparison in the next steps.

### 2. On the failing POOL-FIN-01 host, search the exact Application log for Event 1000 and Event 9009
Portal path:
- Azure Portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > <affected-host> > Virtual machine

Exact log location:
- Event Viewer > Windows Logs > Application

Required Event IDs:
- Event ID 1000
- Event ID 9009

Fields to inspect:
- Logged
- Source
- Event ID
- Level
- Faulting application name
- Faulting module name
- Exception code
- Fault offset
- General message text

Required faulting module in Event 1000:
- igdumd64.dll

Fast PowerShell command on the host:
```powershell
$Start=(Get-Date).AddHours(-6)
Get-WinEvent -FilterHashtable @{LogName='Application'; Id=1000,9009; StartTime=$Start} |
Where-Object { $_.Message -match 'igdumd64\.dll|9009' } |
Select-Object TimeCreated, Id, ProviderName, LevelDisplayName, MachineName, Message |
Format-List
```

Fast Azure CLI command through Run Command if you do not want to RDP to the host:
```powershell
az vm run-command invoke --resource-group <POOL-FIN-01-SESSIONHOST-RG> --name <affected-host-vm> --command-id RunPowerShellScript --scripts "$Start=(Get-Date).AddHours(-6); Get-WinEvent -FilterHashtable @{LogName='Application'; Id=1000,9009; StartTime=$Start} | Where-Object { $_.Message -match 'igdumd64\\.dll|9009' } | Select-Object TimeCreated, Id, ProviderName, LevelDisplayName, Message | Format-List"
```

What to look for:
- Event ID 1000 in Application log at the user-reported failure time.
- In Event ID 1000, the faulting module name must explicitly be igdumd64.dll.
- Event ID 9009 in Application log on the same host in the same incident window.
- The timestamps for Event 1000 and Event 9009 should line up closely with the user login attempt or immediate black-screen period.

### 3. On the healthy POOL-FIN-02 host, confirm the unaffected control event
Portal path:
- Azure Portal > Azure Virtual Desktop > Host pools > POOL-FIN-02 > Session hosts > <healthy-host> > Virtual machine

Exact log location:
- Event Viewer > Windows Logs > Application

Required healthy baseline event:
- Event ID 9011

Fields to inspect:
- Logged
- Source
- Event ID
- Level
- General message text

Fast PowerShell command on the host:
```powershell
$Start=(Get-Date).AddHours(-6)
Get-WinEvent -FilterHashtable @{LogName='Application'; Id=9011; StartTime=$Start} |
Select-Object TimeCreated, Id, ProviderName, LevelDisplayName, MachineName, Message |
Format-List
```

Fast Azure CLI command through Run Command:
```powershell
az vm run-command invoke --resource-group <POOL-FIN-02-SESSIONHOST-RG> --name <healthy-host-vm> --command-id RunPowerShellScript --scripts "$Start=(Get-Date).AddHours(-6); Get-WinEvent -FilterHashtable @{LogName='Application'; Id=9011; StartTime=$Start} | Select-Object TimeCreated, Id, ProviderName, LevelDisplayName, Message | Format-List"
```

What to look for:
- Event ID 9011 exists on the healthy POOL-FIN-02 host during the same general login window.
- POOL-FIN-02 does not show the matching Event 1000 with faulting module igdumd64.dll.
- POOL-FIN-02 does not show the same Event 9009 failure pattern seen on POOL-FIN-01.

### 4. Compare image versions to prove the pool split matches the log evidence
Portal path:
- Azure Portal > Cloud Shell > PowerShell

Commands:
```powershell
az vmss show --resource-group <POOL-FIN-01-VMSS-RG> --name <POOL-FIN-01-VMSS-NAME> --query virtualMachineProfile.storageProfile.imageReference.id -o tsv
az vmss show --resource-group <POOL-FIN-02-VMSS-RG> --name <POOL-FIN-02-VMSS-NAME> --query virtualMachineProfile.storageProfile.imageReference.id -o tsv
```

Field to inspect:
- virtualMachineProfile.storageProfile.imageReference.id

What to look for:
- POOL-FIN-01 is on the changed image version.
- POOL-FIN-02 remains on the prior or otherwise known-good image version.

### 5. Three-minute confirmation threshold
Confirm this KB only when all of the following are true:
- Application log on POOL-FIN-01 shows Event ID 1000 with faulting module igdumd64.dll.
- Application log on POOL-FIN-01 shows Event ID 9009 in the same failure window.
- Application log on POOL-FIN-02 shows Event ID 9011 as the healthy baseline and does not show the same failing Event 1000 plus igdumd64.dll pattern.
- The imageReference.id comparison shows POOL-FIN-01 changed while POOL-FIN-02 remained on the healthy baseline.

## Resolution
### 1. Drain every POOL-FIN-01 session host so no new users land on bad hosts
Portal path:
- Azure Portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > <session-host> > Properties > Allow new sessions

Option to set:
- Allow new sessions = Off

Fast Azure PowerShell command:
```powershell
$HostPoolResourceGroup="<AVD-HOSTPOOL-RG>"
$HostPoolName="POOL-FIN-01"
$SessionHostNames=@("<host1.domain>","<host2.domain>")
foreach ($SessionHostName in $SessionHostNames) {
	Update-AzWvdSessionHost -ResourceGroupName $HostPoolResourceGroup -HostPoolName $HostPoolName -Name $SessionHostName -AllowNewSession:$false
}
```

Fast Azure CLI command:
```powershell
az desktopvirtualization session-host update --resource-group <AVD-HOSTPOOL-RG> --host-pool-name POOL-FIN-01 --name <host1.domain> --allow-new-session false
```

Expected result:
- In Azure Portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts, the Allow new sessions column changes to No for each affected host.
- New logons stop landing on unstable hosts.

### 2. Move impacted users to the healthy POOL-FIN-02 desktop application group
Portal path:
- Azure Portal > Azure Virtual Desktop > Application groups > <POOL-FIN-02-Desktop-App-Group> > Assignments > Add

Option to use:
- Add user, group, or service principal assignment for affected users or the approved fallback group

Fast Azure CLI command:
```powershell
az role assignment create --assignee <user-or-group-object-id> --role "Desktop Virtualization User" --scope <POOL-FIN-02-APP-GROUP-RESOURCE-ID>
```

Expected result:
- Users can launch a working desktop through POOL-FIN-02.
- The assignment is visible under Azure Portal > Azure Virtual Desktop > Application groups > <POOL-FIN-02-Desktop-App-Group> > Assignments.

### 3. Confirm the current POOL-FIN-01 image setting before making any change
Portal path:
- Azure Portal > Virtual machine scale sets > <POOL-FIN-01-VMSS-NAME> > Configuration > Image

Option to inspect:
- Image reference or image version currently assigned to the VMSS model

Fast Azure CLI command:
```powershell
az vmss show --resource-group <POOL-FIN-01-VMSS-RG> --name <POOL-FIN-01-VMSS-NAME> --query "{imageId:virtualMachineProfile.storageProfile.imageReference.id,imagePublisher:virtualMachineProfile.storageProfile.imageReference.publisher,imageOffer:virtualMachineProfile.storageProfile.imageReference.offer,imageSku:virtualMachineProfile.storageProfile.imageReference.sku,imageVersion:virtualMachineProfile.storageProfile.imageReference.version}" -o json
```

Expected result:
- The active image setting is captured in the incident record before any rollback or correction.

### 4. Change the POOL-FIN-01 VMSS image setting to the known-good image
Portal path:
- Azure Portal > Virtual machine scale sets > <POOL-FIN-01-VMSS-NAME> > Configuration > Image > Edit

Option to set:
- Shared Image Gallery or image reference = <KNOWN_GOOD_IMAGE_VERSION_ID>

Fast Azure CLI command:
```powershell
az vmss update --resource-group <POOL-FIN-01-VMSS-RG> --name <POOL-FIN-01-VMSS-NAME> --set virtualMachineProfile.storageProfile.imageReference.id=<KNOWN_GOOD_IMAGE_VERSION_ID>
```

Expected result:
- Azure Portal > Virtual machine scale sets > <POOL-FIN-01-VMSS-NAME> > Configuration > Image shows the known-good image.
- The VMSS model is updated but host instances are not yet fully refreshed.

### 5. Apply the corrected image to one canary host first
Portal path:
- Azure Portal > Virtual machine scale sets > <POOL-FIN-01-VMSS-NAME> > Instances > <canary-instance> > Upgrade

Option to use:
- Upgrade selected instance to latest model

Fast Azure CLI command:
```powershell
az vmss update-instances --resource-group <POOL-FIN-01-VMSS-RG> --name <POOL-FIN-01-VMSS-NAME> --instance-ids <CANARY_INSTANCE_ID>
```

Expected result:
- The selected canary instance starts applying the updated image model.

### 6. Confirm the canary host completed the image refresh
Portal path:
- Azure Portal > Virtual machine scale sets > <POOL-FIN-01-VMSS-NAME> > Instances > <canary-instance>

Options to inspect:
- Provisioning state
- Latest model applied
- Power state

Fast Azure CLI command:
```powershell
az vmss get-instance-view --resource-group <POOL-FIN-01-VMSS-RG> --name <POOL-FIN-01-VMSS-NAME> --instance-id <CANARY_INSTANCE_ID> --query "{instanceId:instanceId,latestModelApplied:latestModelApplied,provisioningState:statuses[?starts_with(code,'ProvisioningState/')].displayStatus|[0],powerState:statuses[?starts_with(code,'PowerState/')].displayStatus|[0]}" -o json
```

Expected result:
- Provisioning state = Succeeded.
- latestModelApplied = true.
- Power state = VM running.

### 7. Validate one user sign-in against the repaired canary host
Portal path:
- Azure Portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > <canary-session-host>

Options to inspect:
- Status = Available
- Allow new sessions = No until test completes
- Sessions count during test

Fast validation command:
```powershell
az desktopvirtualization session-host show --resource-group <AVD-HOSTPOOL-RG> --host-pool-name POOL-FIN-01 --name <canary-session-host-fqdn> -o json
```

Expected result:
- The test user reaches a normal desktop with no black screen.
- The canary session host remains healthy and available after the test.

### 8. Apply the corrected image to all remaining POOL-FIN-01 instances
Portal path:
- Azure Portal > Virtual machine scale sets > <POOL-FIN-01-VMSS-NAME> > Instances > Select all remaining instances > Upgrade

Option to use:
- Upgrade selected instances to latest model

Fast Azure CLI command:
```powershell
az vmss update-instances --resource-group <POOL-FIN-01-VMSS-RG> --name <POOL-FIN-01-VMSS-NAME> --instance-ids "*"
```

Expected result:
- All remaining instances begin applying the corrected image.

### 9. Reopen POOL-FIN-01 to production traffic
Portal path:
- Azure Portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > <session-host> > Properties > Allow new sessions

Option to set:
- Allow new sessions = On

Fast Azure PowerShell command:
```powershell
$HostPoolResourceGroup="<AVD-HOSTPOOL-RG>"
$HostPoolName="POOL-FIN-01"
$SessionHostNames=@("<host1.domain>","<host2.domain>")
foreach ($SessionHostName in $SessionHostNames) {
	Update-AzWvdSessionHost -ResourceGroupName $HostPoolResourceGroup -HostPoolName $HostPoolName -Name $SessionHostName -AllowNewSession:$true
}
```

Expected result:
- In Azure Portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts, the Allow new sessions column changes to Yes.
- POOL-FIN-01 resumes normal production traffic.

## Verification
### 1. Verify every POOL-FIN-01 session host is open and healthy
Portal path:
- Azure Portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts

Options to inspect:
- Status
- Allow new sessions
- Sessions
- Agent version

Fast Azure CLI command:
```powershell
az desktopvirtualization session-host list --resource-group <AVD-HOSTPOOL-RG> --host-pool-name POOL-FIN-01 --query "[].{name:name,status:properties.status,allowNewSession:properties.allowNewSession,sessions:properties.sessions,agentVersion:properties.agentVersion}" -o table
```

Expected result:
- Status = Available.
- Allow new sessions = true.
- Session hosts are accepting users normally.

### 2. Verify the correct image is now applied on the FIN01 host VMSS
Portal path:
- Azure Portal > Virtual machine scale sets > <POOL-FIN-01-VMSS-NAME> > Configuration > Image

Options to inspect:
- Current image reference
- Latest model definition

Fast Azure CLI command:
```powershell
az vmss show --resource-group <POOL-FIN-01-VMSS-RG> --name <POOL-FIN-01-VMSS-NAME> --query "{imageId:virtualMachineProfile.storageProfile.imageReference.id,imageVersion:virtualMachineProfile.storageProfile.imageReference.version}" -o json
```

Expected result:
- The image setting matches the known-good image version used for remediation.

### 3. Verify every FIN01 instance picked up the latest VMSS model
Portal path:
- Azure Portal > Virtual machine scale sets > <POOL-FIN-01-VMSS-NAME> > Instances

Options to inspect:
- Latest model applied
- Provisioning state
- Power state

Fast Azure CLI command:
```powershell
az vmss list-instances --resource-group <POOL-FIN-01-VMSS-RG> --name <POOL-FIN-01-VMSS-NAME> --query "[].{instanceId:instanceId,latestModelApplied:latestModelApplied,provisioningState:provisioningState}" -o table
```

Expected result:
- latestModelApplied = true for all instances.
- provisioningState = Succeeded for all instances.

### 4. Verify successful post-fix user connections on POOL-FIN-01
Portal path:
- Azure Portal > Azure Monitor > Logs > <AVD Log Analytics Workspace>

Log/table:
- WVDConnections

Fields to inspect:
- HostPoolName
- SessionHostName
- ConnectionState
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
- New POOL-FIN-01 sessions complete with normal connected state.

### 5. Verify the fallback POOL-FIN-02 path is no longer carrying incident traffic
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
- Fallback usage is flat or decreasing.

### 6. Verify the crash signature is no longer appearing on the repaired host
Portal path:
- Azure Portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > <tested-host> > Virtual machine
- Event Viewer > Windows Logs > Application

Events to verify are absent for the new validation window:
- Event ID 1000 with faulting module igdumd64.dll
- Event ID 9009

Fast PowerShell command:
```powershell
$Start=(Get-Date).AddMinutes(-30)
Get-WinEvent -FilterHashtable @{LogName='Application'; Id=1000,9009; StartTime=$Start} |
Where-Object { $_.Message -match 'igdumd64\.dll|9009' } |
Select-Object TimeCreated, Id, ProviderName, Message |
Format-List
```

Expected result:
- No new Event ID 1000 with faulting module igdumd64.dll appears after remediation.
- No new Event ID 9009 appears for the validation period.

## Rollback
### 1. Stop all new sessions on POOL-FIN-01 immediately
Portal path:
- Azure Portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > <session-host> > Properties > Allow new sessions

Option to set:
- Allow new sessions = Off

Fast Azure PowerShell command:
```powershell
$HostPoolResourceGroup="<AVD-HOSTPOOL-RG>"
$HostPoolName="POOL-FIN-01"
$SessionHostNames=@("<host1.domain>","<host2.domain>")
foreach ($SessionHostName in $SessionHostNames) {
	Update-AzWvdSessionHost -ResourceGroupName $HostPoolResourceGroup -HostPoolName $HostPoolName -Name $SessionHostName -AllowNewSession:$false
}
```

Expected result:
- No further users land on unstable POOL-FIN-01 hosts.

### 2. Restore fallback routing to the healthy pool
Portal path:
- Azure Portal > Azure Virtual Desktop > Application groups > <POOL-FIN-02-Desktop-App-Group> > Assignments > Add

Option to use:
- Re-add affected users or fallback group membership

Fast Azure CLI command:
```powershell
az role assignment create --assignee <user-or-group-object-id> --role "Desktop Virtualization User" --scope <POOL-FIN-02-APP-GROUP-RESOURCE-ID>
```

Expected result:
- Users regain access through POOL-FIN-02 while rollback is in progress.

### 3. Revert the FIN01 host VMSS image setting to the exact pre-change value
Portal path:
- Azure Portal > Virtual machine scale sets > <POOL-FIN-01-VMSS-NAME> > Configuration > Image > Edit

Option to set:
- Image reference = <PRE_CHANGE_IMAGE_ID>

Fast Azure CLI command:
```powershell
az vmss update --resource-group <POOL-FIN-01-VMSS-RG> --name <POOL-FIN-01-VMSS-NAME> --set virtualMachineProfile.storageProfile.imageReference.id=<PRE_CHANGE_IMAGE_ID>
```

Expected result:
- Azure Portal > Virtual machine scale sets > <POOL-FIN-01-VMSS-NAME> > Configuration > Image shows the pre-change image.

### 4. Apply the rollback image to every FIN01 instance
Portal path:
- Azure Portal > Virtual machine scale sets > <POOL-FIN-01-VMSS-NAME> > Instances > Select all > Upgrade

Option to use:
- Upgrade selected instances to latest model

Fast Azure CLI command:
```powershell
az vmss update-instances --resource-group <POOL-FIN-01-VMSS-RG> --name <POOL-FIN-01-VMSS-NAME> --instance-ids "*"
```

Expected result:
- All instances begin returning to the pre-change image state.

### 5. Verify rollback state before reopening service
Portal path:
- Azure Portal > Virtual machine scale sets > <POOL-FIN-01-VMSS-NAME> > Instances
- Azure Portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts

Options to inspect:
- latestModelApplied = true
- Provisioning state = Succeeded
- Allow new sessions remains Off until rollback validation is complete

Fast Azure CLI commands:
```powershell
az vmss list-instances --resource-group <POOL-FIN-01-VMSS-RG> --name <POOL-FIN-01-VMSS-NAME> --query "[].{instanceId:instanceId,latestModelApplied:latestModelApplied,provisioningState:provisioningState}" -o table
az desktopvirtualization session-host list --resource-group <AVD-HOSTPOOL-RG> --host-pool-name POOL-FIN-01 --query "[].{name:name,status:properties.status,allowNewSession:properties.allowNewSession}" -o table
```

Expected result:
- Rolled-back instances are on the restored model.
- Session hosts stay drained until one rollback validation sign-in succeeds.

## Preventive
1. Owner: release engineer. Timing: before deployment and during deployment. Control: use pilot, finance-canary, and production rings, and do not advance until the prior ring shows zero new Application log Event 1000 with igdumd64.dll and zero Event 9009 across 30 minutes; fail blocks promotion and returns change to image owner. Mode: Manual; automate with release pipeline ring gates [REQUIRES: release gating process].
2. Owner: change manager. Timing: before deployment. Control: record POOL-FIN-01 and POOL-FIN-02 VMSS imageReference.id values in the change record and verify they are different before Finance rollout starts; pass = both values captured and POOL-FIN-02 remains on prior image, fail = change cannot start. Mode: Manual; automate by writing both values into the change ticket from a pre-check script [REQUIRES: change template/process].
3. Owner: image owner. Timing: before deployment. Control: run a smoke test on one canary host that must render a usable desktop within 60 seconds and show zero new Application log Event 1000 with igdumd64.dll and zero Event 9009 in the next 15 minutes; fail returns the image to rework and blocks release. Mode: Automated [REQUIRES: scripted AVD login/render smoke test].
4. Owner: DWP engineer. Timing: during deployment. Control: capture Application log Event 1000, Event 9009, and healthy baseline Event 9011, plus Event IDs 21, 22, 24, and 4101, for the first 60 minutes after rollout; pass = POOL-FIN-01 has zero new 1000 or 9009 and POOL-FIN-02 continues to show 9011, fail opens incident response immediately. Mode: Automated [REQUIRES: log forwarding and alert rules].
5. Owner: release engineer. Timing: during deployment. Control: keep POOL-FIN-02 on the prior image until the POOL-FIN-01 canary shows latestModelApplied = true, provisioningState = Succeeded, and one successful test login with no black screen; fail freezes the rollout and keeps Finance on fallback capacity. Mode: Manual; automate by gating on VMSS instance-view and test-login results [REQUIRES: rollout gate script].
6. Owner: service desk lead. Timing: before deployment and during deployment. Control: maintain a tested fallback assignment group or script for routing users to POOL-FIN-02, and test it monthly with one non-production user assignment; pass = assignment visible in the app group within 5 minutes, fail creates an access-process defect for repair before the next release. Mode: Manual; automate with a group-based assignment script [REQUIRES: fallback assignment process].
7. Owner: image owner. Timing: before deployment. Control: run a pre-deployment test gate against the candidate image on a non-production host and verify one login, one sign-out, and zero Application log Event 1000 or 9009 within 15 minutes; fail blocks image publication to the production gallery. Mode: Automated [REQUIRES: image promotion gate].
8. Owner: DWP engineer. Timing: during deployment. Control: run in-flight monitoring for the rollout window with alert thresholds of Event 1000 count >= 1 with igdumd64.dll, Event 9009 count >= 1 on POOL-FIN-01, or two user black-screen reports within 10 minutes; fail triggers rollback assessment immediately. Mode: Automated for events, Manual for user-report count [REQUIRES: alert rule and incident triage queue].
9. Owner: change manager. Timing: after deployment. Control: do not close the change until POOL-FIN-01 shows all session hosts Available, Allow new sessions = true, latestModelApplied = true on all instances, and POOL-FIN-02 fallback connections return to baseline within 30 minutes; fail keeps the change open and assigned to DWP engineering. Mode: Manual; automate with a post-change validation report [REQUIRES: closure checklist].
10. Owner: DWP engineer. Timing: during deployment and after deployment. Control: use a rollback trigger of any canary black-screen reproduction, any Event 1000 with igdumd64.dll on the canary, any Event 9009 after image apply, or more than 2 affected Finance users in 10 minutes; fail condition means rollback is mandatory, not optional. Mode: Manual decision using automated signals [REQUIRES: rollback threshold approval in change record].
11. Owner: image owner. Timing: after deployment. Control: update the runbook, KB, and release checklist within 1 business day of any confirmed incident or near miss, including exact Event IDs, module name, and image comparison steps; pass = revised documents linked in the ticket, fail = change manager rejects closure. Mode: Manual; automate with a mandatory documentation task in the change workflow [REQUIRES: documentation update process].

## Related
- AVD black screen runbook for POOL-FIN-01.
- AVD black screen known error record.
- AVD black screen solution note.
- Future KBs for FSLogix profile attach failures and AVD sign-in failures.