# Solution Note: AVD Black Screen After Login (POOL-FIN-01)

Version header: v 1.0, 07/08/2026, status : Draft

## Objective
Restore Finance user access by routing users to the healthy pool, correcting the POOL-FIN-01 image state, and validating the fix before reopening production traffic.

## Step-by-Step Fix
1. Azure Portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts
Set Allow new sessions = No on affected hosts.
Expected result: new user sessions stop landing on unstable hosts.

2. Azure Portal > Azure Virtual Desktop > Application groups > <POOL-FIN-02-Desktop-App-Group> > Assignments
Add affected users or fallback group membership.
Expected result: users regain working desktop access through POOL-FIN-02.

3. Azure Portal > Cloud Shell > PowerShell
Run:
```powershell
az vmss show --resource-group <POOL-FIN-01-VMSS-RG> --name <POOL-FIN-01-VMSS-NAME> --query virtualMachineProfile.storageProfile.imageReference.id -o tsv
```
Expected result: the current bad image reference is recorded.

4. Azure Portal > Cloud Shell > PowerShell
Run:
```powershell
az vmss update --resource-group <POOL-FIN-01-VMSS-RG> --name <POOL-FIN-01-VMSS-NAME> --set virtualMachineProfile.storageProfile.imageReference.id=<KNOWN_GOOD_IMAGE_VERSION_ID>
```
Expected result: the VMSS model points to the known-good image.

5. Azure Portal > Cloud Shell > PowerShell
Run:
```powershell
az vmss update-instances --resource-group <POOL-FIN-01-VMSS-RG> --name <POOL-FIN-01-VMSS-NAME> --instance-ids <CANARY_INSTANCE_ID>
```
Expected result: the canary instance begins applying the corrected model.

6. Azure Portal > Virtual machine scale sets > <POOL-FIN-01-VMSS-NAME> > Instances
Wait for Provisioning state = Succeeded.
Expected result: the canary host is ready for validation.

7. Azure Portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts
Run one controlled validation login.
Expected result: the desktop renders normally and the black screen does not recur.

8. Azure Portal > Cloud Shell > PowerShell
Run:
```powershell
az vmss update-instances --resource-group <POOL-FIN-01-VMSS-RG> --name <POOL-FIN-01-VMSS-NAME> --instance-ids "*"
```
Expected result: all remaining POOL-FIN-01 instances begin applying the corrected image.

9. Azure Portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts
Set Allow new sessions = Yes after rollout completes.
Expected result: POOL-FIN-01 resumes normal traffic.

10. Azure Portal > Azure Virtual Desktop > Application groups > <POOL-FIN-02-Desktop-App-Group> > Assignments
Remove the temporary fallback assignment.
Expected result: users route back to their standard POOL-FIN-01 path.

## Verification Checks
- WVDConnections shows successful new POOL-FIN-01 sessions.
- POOL-FIN-02 fallback usage decreases after users are moved back.
- TerminalServices-LocalSessionManager shows Event IDs 21 and 22 for the successful validation login.
- Windows System log does not show a new Event ID 4101 during validation.

## Rollback Trigger
Rollback immediately if the canary host still shows the black screen, if the VMSS rollout fails, or if the corrected image introduces broader instability.