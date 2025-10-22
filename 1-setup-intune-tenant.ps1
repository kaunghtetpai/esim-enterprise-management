# eSIM Enterprise Management Portal - Tenant Setup
# Admin: admin@mdm.esim.com.mm

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "DeviceManagementConfiguration.ReadWrite.All", "DeviceManagementManagedDevices.ReadWrite.All", "Group.ReadWrite.All"

# Create device groups for Myanmar carriers
$carriers = @("MPT", "ATOM", "OOREDOO", "MYTEL")
foreach ($carrier in $carriers) {
    $group = @{
        displayName = "eSIM-$carrier-Devices"
        description = "Devices with $carrier eSIM profiles"
        mailNickname = "esim$($carrier.ToLower())devices"
        groupTypes = @("DynamicMembership")
        membershipRule = "(device.deviceModel -contains `"eSIM`") and (device.extensionAttribute1 -eq `"$carrier`")"
        membershipRuleProcessingState = "On"
        mailEnabled = $false
        securityEnabled = $true
    }
    New-MgGroup -BodyParameter $group
    Write-Host "Created group: eSIM-$carrier-Devices"
}

# Create platform-specific groups
$platforms = @("Windows", "iOS", "Android")
foreach ($platform in $platforms) {
    $group = @{
        displayName = "eSIM-$platform-Devices"
        description = "$platform devices with eSIM capability"
        mailNickname = "esim$($platform.ToLower())devices"
        groupTypes = @("DynamicMembership")
        membershipRule = "(device.deviceOSType -eq `"$platform`") and (device.deviceModel -contains `"eSIM`")"
        membershipRuleProcessingState = "On"
        mailEnabled = $false
        securityEnabled = $true
    }
    New-MgGroup -BodyParameter $group
    Write-Host "Created group: eSIM-$platform-Devices"
}