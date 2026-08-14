# L2 Technical Article: Floor 6 Login Regression (App Rollback Path)

Version: v4.0  
Date: 2026-08-14  
Source runbook: floor6-runbook-login-app-regression-v4.md

## Trigger
Use this when Floor 6 login failures/slowness align with Friday app rollout and app-regression is top-ranked hypothesis.

## Recovery Procedure (Runbook-Derived)
1. Pre-change evidence capture:
```powershell
.\floor6-login-check-corrected.ps1 -AppDisplayName "FinBridge Document Management" -LookbackHours 72 -OutputPath "C:\Temp\Floor6-Pre.json"
```

2. Uninstall assignment:
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

3. Force sync sampled devices:
```powershell
$managedDeviceIds = @("<DEVICE_ID_1>","<DEVICE_ID_2>","<DEVICE_ID_3>")
foreach ($id in $managedDeviceIds) {
  Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$id/syncDevice"
}
```

4. Validate recovery and collect post-change evidence:
```powershell
.\floor6-login-check-corrected.ps1 -AppDisplayName "FinBridge Document Management" -LookbackHours 24 -OutputPath "C:\Temp\Floor6-Post.json"
```

## Verification Criteria
- Uninstall intent applied to Floor 6 ring.
- Pilot sign-in times improve.
- Incident volume declines.
- IME retry-loop signature not sustained post-change.

## Rollback-of-Rollback
If app must be restored, remove uninstall assignment and redeploy to pilot only before broad scope.
