# Floor 6 Immediate Fix and User Message

Version: v4.0  
Date: 2026-08-14  
Owner: DWP Engineering

## Technical Action (Exact Command)

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

Optional acceleration:

```powershell
$managedDeviceIds = @("<DEVICE_ID_1>","<DEVICE_ID_2>","<DEVICE_ID_3>")
foreach ($id in $managedDeviceIds) {
  Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$id/syncDevice"
}
```

## Plain-Language Note to Floor 6
We found a likely link between Friday's software change and this morning's sign-in issues for Floor 6, and we are now removing that change from affected devices. Your files are safe, and we will continue updates while we verify recovery device by device.
