# eSIM Profile Configuration for Myanmar Carriers

# Myanmar carrier configurations
$carriers = @{
    "MPT" = @{
        name = "Myanmar Posts and Telecommunications"
        apn = "internet"
        mcc = "414"
        mnc = "01"
    }
    "ATOM" = @{
        name = "Atom Myanmar"
        apn = "internet"
        mcc = "414"
        mnc = "06"
    }
    "OOREDOO" = @{
        name = "Ooredoo Myanmar"
        apn = "internet"
        mcc = "414"
        mnc = "05"
    }
    "MYTEL" = @{
        name = "MyTel Myanmar"
        apn = "internet"
        mcc = "414"
        mnc = "09"
    }
}

foreach ($carrier in $carriers.Keys) {
    $config = $carriers[$carrier]
    
    # Create eSIM configuration profile
    $profile = @{
        "@odata.type" = "#microsoft.graph.windows10CustomConfiguration"
        displayName = "eSIM-$carrier-Profile"
        description = "eSIM configuration for $($config.name)"
        omaSettings = @(
            @{
                "@odata.type" = "#microsoft.graph.omaSettingString"
                displayName = "Enable eSIM Local UI"
                omaUri = "./Device/Vendor/MSFT/eUICCs/{eUICC}/Policies/LocalUIEnabled"
                value = "true"
            },
            @{
                "@odata.type" = "#microsoft.graph.omaSettingString"
                displayName = "Carrier APN"
                omaUri = "./Device/Vendor/MSFT/eUICCs/{eUICC}/Profiles/{ICCID}/APN"
                value = $config.apn
            },
            @{
                "@odata.type" = "#microsoft.graph.omaSettingString"
                displayName = "MCC-MNC"
                omaUri = "./Device/Vendor/MSFT/eUICCs/{eUICC}/Profiles/{ICCID}/PLMN"
                value = "$($config.mcc)$($config.mnc)"
            }
        )
    }
    
    try {
        $createdProfile = New-MgDeviceManagementDeviceConfiguration -BodyParameter $profile
        Write-Host "Created eSIM profile: $carrier" -ForegroundColor Green
        
        # Assign to carrier group
        $groupId = (Get-MgGroup -Filter "displayName eq 'eSIM-$carrier-Devices'").Id
        if ($groupId) {
            $assignment = @{
                target = @{
                    "@odata.type" = "#microsoft.graph.groupAssignmentTarget"
                    groupId = $groupId
                }
            }
            New-MgDeviceManagementDeviceConfigurationAssignment -DeviceConfigurationId $createdProfile.Id -BodyParameter $assignment
            Write-Host "Assigned profile to eSIM-$carrier-Devices group"
        }
    } catch {
        Write-Warning "Failed to create profile for $carrier : $($_.Exception.Message)"
    }
}