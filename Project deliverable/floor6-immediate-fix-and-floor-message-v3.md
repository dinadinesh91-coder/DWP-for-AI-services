# Floor 6 Immediate Fix and Message

Version: v3.0  
Date: 2026-08-14  
Owner: DWP Engineering

## Most-Likely Cause (Working)
Friday app deployment regression on Floor 6 endpoints, based on tight timing and scope correlation.

## Immediate Technical Action
Apply uninstall intent to the Floor 6 device ring for the deployed Win32 app.

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

Optional acceleration for sampled impacted devices:

```powershell
$managedDeviceIds = @("<DEVICE_ID_1>","<DEVICE_ID_2>","<DEVICE_ID_3>")
foreach ($id in $managedDeviceIds) {
  Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$id/syncDevice"
}
```

## Plain-Language Message to Floor 6
We found a likely link between Friday's software update and this morning's sign-in issues on Floor 6, and we are now removing that update from affected devices. Your files are safe, and we will keep sending regular updates while we confirm recovery device by device.
