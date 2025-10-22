# Update Windows from Cloud - Windows Update for Business
Connect-MgGraph -Scopes "DeviceManagementConfiguration.ReadWrite.All"

$updatePolicy = @{
    "@odata.type" = "#microsoft.graph.windowsUpdateForBusinessConfiguration"
    displayName = "eSIM Windows Update Policy"
    description = "Automatic Windows updates for eSIM devices"
    automaticUpdateMode = "autoInstallAtMaintenanceTime"
    businessReadyUpdatesOnly = "businessReadyOnly"
    deliveryOptimizationMode = "httpOnly"
    driversExcluded = $false
    featureUpdatesDeferralPeriodInDays = 0
    qualityUpdatesDeferralPeriodInDays = 0
    installationSchedule = @{
        "@odata.type" = "#microsoft.graph.windowsUpdateActiveHoursInstall"
        activeHoursStart = "08:00:00.0000000"
        activeHoursEnd = "17:00:00.0000000"
    }
}

$policy = New-MgDeviceManagementDeviceConfiguration -BodyParameter $updatePolicy
Write-Host "Windows Update policy created: $($policy.Id)" -ForegroundColor Green

# Assign to Windows eSIM devices
$windowsGroup = Get-MgGroup -Filter "displayName eq 'eSIM-Windows-Devices'"
if ($windowsGroup) {
    $assignment = @{
        target = @{
            "@odata.type" = "#microsoft.graph.groupAssignmentTarget"
            groupId = $windowsGroup.Id
        }
    }
    New-MgDeviceManagementDeviceConfigurationAssignment -DeviceConfigurationId $policy.Id -BodyParameter $assignment
    Write-Host "Policy assigned to Windows eSIM devices" -ForegroundColor Green
}