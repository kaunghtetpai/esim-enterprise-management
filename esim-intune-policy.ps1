# eSIM Intune Policy Configuration
Connect-MgGraph -Scopes "DeviceManagementConfiguration.ReadWrite.All"

# Create custom OMA-URI policy for eSIM
$policy = @{
    "@odata.type" = "#microsoft.graph.windows10CustomConfiguration"
    displayName = "eSIM Configuration Policy"
    description = "Configure eSIM settings via CSP"
    omaSettings = @(
        @{
            "@odata.type" = "#microsoft.graph.omaSettingString"
            displayName = "Enable eSIM Local UI"
            omaUri = "./Device/Vendor/MSFT/eUICCs/{eUICC}/Policies/LocalUIEnabled"
            value = "true"
        },
        @{
            "@odata.type" = "#microsoft.graph.omaSettingString"
            displayName = "Allow PPR1"
            omaUri = "./Device/Vendor/MSFT/eUICCs/{eUICC}/Policies/PPR1Allowed"
            value = "true"
        }
    )
}

# Create the policy
$createdPolicy = New-MgDeviceManagementDeviceConfiguration -BodyParameter $policy
Write-Host "eSIM policy created: $($createdPolicy.Id)"