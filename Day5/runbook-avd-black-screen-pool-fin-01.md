# Runbook: AVD Black Screen After Login (POOL-FIN-01)

## Version Header
- Title: AVD Black Screen After Login (POOL-FIN-01)
- Version: 1.0
- Date: 07/08/2026
- Author: Sathishbabu
- reviewed: self
- status: draft
- change: initial version from RCA

## Prerequisites
- [ ] Access check: Confirm your account has Desktop Virtualization Contributor on the POOL-FIN-01 and POOL-FIN-02 resource groups. [ELEVATED]
- [ ] Access check: Confirm your account has Virtual Machine Contributor on all session host VMs in POOL-FIN-01. [ELEVATED]
- [ ] Access check: Confirm your account has permission to update Entra ID group membership used for AVD app-group assignment. [ELEVATED]
- [ ] Access check: Confirm your account has Log Analytics Reader on the AVD diagnostics workspace.
- [ ] Tool check: Sign in to Azure Portal from an admin workstation.
- [ ] Tool check: Confirm Azure CLI is installed by running `az --version` in PowerShell.
- [ ] Tool check: Confirm Remote Desktop client is installed for test login validation.
- [ ] Mandatory end-user info: Collect affected username (UPN and SAM), for example `cthompson@finbridge.local` and `FINBRIDGE\\cthompson`.
- [ ] Mandatory end-user info: Collect exact failure time window in local time and UTC.
- [ ] Mandatory end-user info: Collect impacted host pool name and app group name shown to user at login.
- [ ] Mandatory end-user info: Collect client type used by user (Windows app, web client, or thin client).
- [ ] Mandatory end-user info: Collect screenshot text or error prompt shown during black-screen event.
- [ ] Mandatory end-user info: Collect whether screen stays black or clears after ~30 seconds.
- [ ] Mandatory operations info: Identify healthy fallback app group mapped to POOL-FIN-02.
- [ ] Mandatory operations info: Identify last known-good image version ID from the previous successful deployment change record.
- [ ] Mandatory operations info: Identify POOL-FIN-01 VMSS name and resource group for session hosts.
- [ ] Mandatory operations info: Confirm incident ticket ID is open and assigned.

## Procedure
1. Open Azure Portal and go to `Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts`. Expected result: session host list for POOL-FIN-01 is displayed.
2. Open Azure Portal and go to `Azure Monitor > Logs > <AVD-Log-Analytics-Workspace>`. Expected result: the query editor opens for the AVD workspace.
3. Run this query in Log Analytics:
```kusto
WVDConnections
| where TimeGenerated between (ago(6h) .. now())
| where HostPoolName =~ "POOL-FIN-01"
| project TimeGenerated, UserName, HostPoolName, SessionHostName, ConnectionState, CorrelationId
| order by TimeGenerated desc
```
Expected result: recent POOL-FIN-01 connection events are returned.
4. Run this query in Log Analytics:
```kusto
WVDErrors
| where TimeGenerated between (ago(6h) .. now())
| where HostPoolName =~ "POOL-FIN-01"
| project TimeGenerated, UserName, SessionHostName, Code, Message, CorrelationId
| order by TimeGenerated desc
```
Expected result: recent AVD broker/agent error events for POOL-FIN-01 are returned.
5. Open one impacted session host VM from `Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > <host> > Virtual machine`. Expected result: VM overview page for the selected host is displayed.
6. Connect to the selected session host using Bastion or approved admin access method. [ELEVATED] Expected result: you have an admin session on the host.
7. Open Event Viewer on the host at `Event Viewer > Applications and Services Logs > Microsoft > Windows > TerminalServices-LocalSessionManager > Operational`. [ELEVATED] Expected result: RDS session lifecycle events are visible.
8. Open Event Viewer on the host at `Event Viewer > Applications and Services Logs > Microsoft > Windows > RemoteDesktopServices-RdpCoreTS > Operational`. [ELEVATED] Expected result: RDP transport/connection events are visible.
9. Open FSLogix logs at `C:\ProgramData\FSLogix\Logs\Profile\` on the host. [ELEVATED] Expected result: profile attach/detach log files are visible with current timestamps.
10. Set `Allow new sessions` to `No` for each affected POOL-FIN-01 session host from `Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts`. [ELEVATED] Expected result: affected hosts show drain mode and stop accepting new logins.
11. Add affected users to the fallback app-group assignment for POOL-FIN-02 in `Azure Virtual Desktop > Application groups > <POOL-FIN-02-App-Group> > Assignments`. [ELEVATED] Expected result: affected users can launch a working desktop via POOL-FIN-02.
12. Record the current image reference ID in the incident ticket by running this command in Azure Cloud Shell PowerShell: `az vmss show --resource-group <POOL-FIN-01-VMSS-RG> --name <POOL-FIN-01-VMSS-NAME> --query virtualMachineProfile.storageProfile.imageReference.id -o tsv`. [ELEVATED] Expected result: ticket contains exact pre-change image reference ID.
13. Set the VMSS image to the known-good image version ID by running this command in Azure Cloud Shell PowerShell: `az vmss update --resource-group <POOL-FIN-01-VMSS-RG> --name <POOL-FIN-01-VMSS-NAME> --set virtualMachineProfile.storageProfile.imageReference.id=<KNOWN_GOOD_IMAGE_VERSION_ID>`. [ELEVATED] Expected result: VMSS model points to the known-good image.
14. Trigger model rollout to one canary instance by running this command in Azure Cloud Shell PowerShell: `az vmss update-instances --resource-group <POOL-FIN-01-VMSS-RG> --name <POOL-FIN-01-VMSS-NAME> --instance-ids <CANARY_INSTANCE_ID>`. [ELEVATED] Expected result: canary instance applies the updated model.
15. Confirm canary provisioning completion in Azure Portal at `Virtual machine scale sets > <POOL-FIN-01-VMSS-NAME> > Instances`. [ELEVATED] Expected result: canary instance shows Provisioning state Succeeded.
16. Perform one test login to the canary host using an affected user account. Expected result: desktop loads without black screen.
17. Roll out the same image model to all remaining instances by running this command in Azure Cloud Shell PowerShell: `az vmss update-instances --resource-group <POOL-FIN-01-VMSS-RG> --name <POOL-FIN-01-VMSS-NAME> --instance-ids "*"`. [ELEVATED] Expected result: all instances start applying the known-good model.
18. Confirm full rollout completion in Azure Portal at `Virtual machine scale sets > <POOL-FIN-01-VMSS-NAME> > Instances`. [ELEVATED] Expected result: all targeted instances show Provisioning state Succeeded.
19. Set `Allow new sessions` to `Yes` on remediated POOL-FIN-01 session hosts. [ELEVATED] Expected result: remediated hosts accept new user sessions.
20. Remove temporary fallback assignment from users in `Azure Virtual Desktop > Application groups > <POOL-FIN-02-App-Group> > Assignments`. [ELEVATED] Expected result: users route back to normal POOL-FIN-01 path.
21. Add closure timeline entries to the incident ticket for workaround start, canary validation, full rollout finish, and user confirmation. Expected result: ticket contains a complete and auditable execution timeline.

## Verification
1. Open Azure Portal and go to `Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts`. Expected result: all remediated hosts show `Status = Available` and `Allow new sessions = Yes`.
2. Open Azure Portal and go to `Azure Monitor > Logs > <AVD-Log-Analytics-Workspace>`. Expected result: Log Analytics query editor is open.
3. Run this query in Log Analytics:
```kusto
WVDConnections
| where TimeGenerated between (ago(30m) .. now())
| where HostPoolName =~ "POOL-FIN-01"
| where ConnectionState =~ "Connected"
| summarize SuccessfulConnections=count() by SessionHostName
| order by SuccessfulConnections desc
```
Expected result: successful connection counts are returned for POOL-FIN-01 hosts.
4. Run this query in Log Analytics:
```kusto
WVDErrors
| where TimeGenerated between (ago(30m) .. now())
| where HostPoolName =~ "POOL-FIN-01"
| summarize ErrorCount=count() by Code, Message
| order by ErrorCount desc
```
Expected result: error summary is low or zero and shows no active spike.
5. Run this query in Log Analytics:
```kusto
WVDConnections
| where TimeGenerated between (ago(30m) .. now())
| where HostPoolName =~ "POOL-FIN-02"
| summarize FallbackConnections=count()
```
Expected result: fallback connection count is stable or dropping after users are moved back.
6. Open Azure Portal and go to `Azure Virtual Desktop > Application groups > <POOL-FIN-02-App-Group> > Assignments`. Expected result: temporary incident users are removed from fallback assignment.
7. Connect to one remediated session host and open `Event Viewer > Applications and Services Logs > Microsoft > Windows > TerminalServices-LocalSessionManager > Operational`. [ELEVATED] Expected result: new successful session creation events are present with current timestamps.
8. Open `C:\ProgramData\FSLogix\Logs\Profile\` on the same session host and open the newest log file. [ELEVATED] Expected result: no current profile attach failures for tested users.
9. Record evidence in the incident ticket with query export screenshots, tested usernames, session host names, and timestamps. Expected result: closure packet is complete and auditable.

## Rollback (3-Minute Execution Target)
1. Open Azure Portal and go to `Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts`. Expected result: POOL-FIN-01 host list is visible.
2. Set `Allow new sessions = No` for all POOL-FIN-01 session hosts. [ELEVATED] Expected result: new user logons to unstable hosts stop immediately.
3. Open Azure Portal and go to `Azure Virtual Desktop > Application groups > <POOL-FIN-02-App-Group> > Assignments`. Expected result: assignment blade is open.
4. Add all currently impacted users to `<POOL-FIN-02-App-Group>` assignments. [ELEVATED] Expected result: impacted users can launch fallback desktops immediately.
5. Open Azure Cloud Shell (PowerShell) and run this command exactly: `az vmss update --resource-group <POOL-FIN-01-VMSS-RG> --name <POOL-FIN-01-VMSS-NAME> --set virtualMachineProfile.storageProfile.imageReference.id=<PRE_CHANGE_IMAGE_ID>`. [ELEVATED] Expected result: VMSS model points to the pre-change image.
6. In Azure Cloud Shell (PowerShell), run this command exactly: `az vmss update-instances --resource-group <POOL-FIN-01-VMSS-RG> --name <POOL-FIN-01-VMSS-NAME> --instance-ids "*"`. [ELEVATED] Expected result: rollback rollout starts on all instances.
7. Open Azure Portal and go to `Azure Monitor > Logs > <AVD-Log-Analytics-Workspace>` and run this query:
```kusto
WVDConnections
| where TimeGenerated between (ago(15m) .. now())
| where HostPoolName =~ "POOL-FIN-02"
| summarize ActiveFallbackConnections=count() by bin(TimeGenerated, 5m)
| order by TimeGenerated desc
```
Expected result: active fallback connections are visible during rollback.
8. Post rollback start time, commands executed, and fallback-routing status in the incident ticket and on-call channel. Expected result: all responders have one confirmed rollback status update.

## Notes
- Symptom profile from RCA: black screen appears immediately after login in POOL-FIN-01; some sessions recover after about 30 seconds and some do not.
- Scope from RCA: partial impact in POOL-FIN-01 and no impact in POOL-FIN-02.
- Known cause from RCA set: image-introduced graphics driver regression in the 02:00 POOL-FIN-01 update wave.
- Warning: this RCA set does not provide a reliable event-ID signature for detection, so use pool-scope and post-update timing as primary triage signals.
- Edge case: if only a subset of hosts fail after rollback, compare image version drift host-by-host before resuming user routing.
- Related incident records: Day4 analysis hypothesis, known error record, and closure note for AVD black screen in POOL-FIN-01.
