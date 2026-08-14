[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$AppId,

    [Parameter(Mandatory = $true)]
    [string]$Floor6DeviceGroupId,

    [switch]$DryRun,

    [switch]$SkipGraphConnect,

    [string[]]$Scopes = @(
        "DeviceManagementApps.ReadWrite.All",
        "Group.Read.All"
    )
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$assignUri = "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/$AppId/assign"

$assignmentBody = @{
    mobileAppAssignments = @(
        @{
            "@odata.type" = "#microsoft.graph.mobileAppAssignment"
            intent = "uninstall"
            target = @{
                "@odata.type" = "#microsoft.graph.groupAssignmentTarget"
                groupId = $Floor6DeviceGroupId
            }
        }
    )
}

$payloadJson = $assignmentBody | ConvertTo-Json -Depth 8

if ($DryRun) {
    [pscustomobject]@{
        Mode = "DryRun"
        Hypothesis = "Ranked #1 cause: Friday app deployment regression on Floor 6"
        Action = "Set uninstall assignment for app on Floor 6 device group"
        Uri = $assignUri
        Payload = ($payloadJson | ConvertFrom-Json)
        Note = "No changes were executed."
    } | ConvertTo-Json -Depth 12
    return
}

if (-not $SkipGraphConnect) {
    Connect-MgGraph -Scopes $Scopes | Out-Null
}

if ($PSCmdlet.ShouldProcess("AppId=$AppId GroupId=$Floor6DeviceGroupId", "Apply uninstall assignment via Graph")) {
    $result = Invoke-MgGraphRequest -Method POST -Uri $assignUri -Body $payloadJson -ContentType "application/json"

    [pscustomobject]@{
        Mode = "Execute"
        Hypothesis = "Ranked #1 cause: Friday app deployment regression on Floor 6"
        Action = "Uninstall assignment submitted"
        Uri = $assignUri
        AppId = $AppId
        Floor6DeviceGroupId = $Floor6DeviceGroupId
        GraphResponse = $result
    } | ConvertTo-Json -Depth 12
}
