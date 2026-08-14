# Runbook: Floor 6 Login Fix via App Rollback

Version: v3.0  
Date: 2026-08-14  
Owner: DWP Engineering

## Objective
Restore normal sign-in performance for Floor 6 by rolling back the Friday app deployment from the affected device ring.

## Prerequisites
1. Incident ticket is open and owner assigned.
2. Win32 app ID is confirmed.
3. Floor 6 device group ID is confirmed.
4. Three impacted managed device IDs are available for sync/verification.
5. Graph permissions available:
- DeviceManagementApps.ReadWrite.All
- Group.Read.All
- DeviceManagementManagedDevices.PrivilegedOperations.All

## Procedure

1. Capture pre-change evidence on one impacted endpoint.
Command:
```powershell
.\floor6-login-check-corrected.ps1 -AppDisplayName "FinBridge Document Management" -LookbackHours 72 -OutputPath "C:\Temp\Floor6-Pre.json"
```
Expected result:
- Structured JSON generated with app, profile, performance, and IME evidence.

2. Submit uninstall assignment for Floor 6 ring.
Command:
```powershell
Connect-MgGraph -Scopes "DeviceManagementApps.ReadWrite.All","Group.Read.All"
$appId = "<WIN32_APP_ID>"
$floor6DeviceGroupId = "<FLOOR6_DEVICE_GROUP_ID>"
$body = @{
  mobileAppAssignments = @(
    @{
      "@odata.type" = "#microsoft.graph.mobileAppAssignment"
      intent = "uninstall"
      target = @{
        "@odata.type" = "#microsoft.graph.groupAssignmentTarget"
        groupId = $floor6DeviceGroupId
      }
    }
  )
}
Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/$appId/assign" -Body ($body | ConvertTo-Json -Depth 8)
```
Expected result:
- Graph accepts assignment request and uninstall intent is visible.

3. Force device sync on sampled impacted devices.
Command:
```powershell
$managedDeviceIds = @("<DEVICE_ID_1>","<DEVICE_ID_2>","<DEVICE_ID_3>")
foreach ($id in $managedDeviceIds) {
  Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$id/syncDevice"
}
```
Expected result:
- Devices receive sync request and reevaluate app assignment.

4. Validate pilot recovery.
Checks:
- App uninstall state changes to success.
- Sign-in duration drops from incident baseline.
- New sign-in failure tickets decline in pilot subset.
Expected result:
- At least 2 out of 3 sampled devices show clear recovery trend.

5. Capture post-change evidence.
Command:
```powershell
.\floor6-login-check-corrected.ps1 -AppDisplayName "FinBridge Document Management" -LookbackHours 24 -OutputPath "C:\Temp\Floor6-Post.json"
```
Expected result:
- Reduced profile/performance error density and no sustained IME retry pattern.

## Verification
1. Intune confirms uninstall applied across Floor 6 ring.
2. Service desk incident volume for sign-in issues drops through next business cycle.
3. Affected users confirm improved sign-in performance.

## Rollback (If App Must Be Restored)
1. Remove uninstall assignment.
2. Reassign app to small pilot ring only.
3. Monitor one full business day.
4. Expand gradually only if no regression appears.
