# OneDrive and BitLocker Policy Compliance Check
# Validates drive encryption and backup policies for eSIM devices

function Test-OneDrivePolicies {
    Write-Host "=== OneDrive Policy Analysis ===" -ForegroundColor Cyan
    
    try {
        # Get OneDrive configuration profiles
        $onedriveProfiles = Get-MgDeviceManagementDeviceConfiguration -All | 
            Where-Object { $_.DisplayName -like "*OneDrive*" -or $_.'@odata.type' -like "*oneDrive*" }
        
        $results = @{
            Profiles = $onedriveProfiles.Count
            Issues = @()
            Recommendations = @()
        }
        
        if ($onedriveProfiles.Count -eq 0) {
            $results.Issues += "No OneDrive configuration profiles found"
            $results.Recommendations += "Create OneDrive Known Folder Move policy"
        }
        
        foreach ($profile in $onedriveProfiles) {
            $assignments = Get-MgDeviceManagementDeviceConfigurationAssignment -DeviceConfigurationId $profile.Id
            if (!$assignments) {
                $results.Issues += "OneDrive profile '$($profile.DisplayName)' has no assignments"
            } else {
                Write-Host "+ OneDrive Profile: $($profile.DisplayName)" -ForegroundColor Green
            }
        }
        
        Write-Host "  OneDrive Profiles: $($results.Profiles)" -ForegroundColor White
        Write-Host "  Issues: $($results.Issues.Count)" -ForegroundColor $(if($results.Issues.Count -gt 0){"Red"}else{"Green"})
        
        return $results
        
    } catch {
        Write-Error "Failed to analyze OneDrive policies: $($_.Exception.Message)"
        return $null
    }
}

function Test-BitLockerPolicies {
    Write-Host "`n=== BitLocker Policy Analysis ===" -ForegroundColor Cyan
    
    try {
        # Get BitLocker/encryption policies
        $encryptionProfiles = Get-MgDeviceManagementDeviceConfiguration -All | 
            Where-Object { 
                $_.DisplayName -like "*BitLocker*" -or 
                $_.DisplayName -like "*Encryption*" -or
                $_.'@odata.type' -like "*endpointProtection*"
            }
        
        $results = @{
            Profiles = $encryptionProfiles.Count
            Issues = @()
            Recommendations = @()
        }
        
        if ($encryptionProfiles.Count -eq 0) {
            $results.Issues += "No BitLocker/encryption policies found"
            $results.Recommendations += "Create BitLocker encryption policy for Windows devices"
        }
        
        foreach ($profile in $encryptionProfiles) {
            $assignments = Get-MgDeviceManagementDeviceConfigurationAssignment -DeviceConfigurationId $profile.Id
            if (!$assignments) {
                $results.Issues += "Encryption profile '$($profile.DisplayName)' has no assignments"
            } else {
                Write-Host "+ Encryption Profile: $($profile.DisplayName)" -ForegroundColor Green
            }
        }
        
        Write-Host "  Encryption Profiles: $($results.Profiles)" -ForegroundColor White
        Write-Host "  Issues: $($results.Issues.Count)" -ForegroundColor $(if($results.Issues.Count -gt 0){"Red"}else{"Green"})
        
        return $results
        
    } catch {
        Write-Error "Failed to analyze BitLocker policies: $($_.Exception.Message)"
        return $null
    }
}

function Test-DeviceEncryptionCompliance {
    Write-Host "`n=== Device Encryption Compliance ===" -ForegroundColor Cyan
    
    try {
        $devices = Get-MgDeviceManagementManagedDevice -All
        $encryptionStats = @{
            Total = $devices.Count
            Encrypted = 0
            NotEncrypted = 0
            Unknown = 0
            NonCompliant = @()
        }
        
        foreach ($device in $devices) {
            if ($device.IsEncrypted -eq $true) {
                $encryptionStats.Encrypted++
            } elseif ($device.IsEncrypted -eq $false) {
                $encryptionStats.NotEncrypted++
                $encryptionStats.NonCompliant += $device
            } else {
                $encryptionStats.Unknown++
            }
        }
        
        $encryptionPercentage = if ($encryptionStats.Total -gt 0) { 
            [math]::Round(($encryptionStats.Encrypted / $encryptionStats.Total) * 100, 2) 
        } else { 0 }
        
        Write-Host "  Total Devices: $($encryptionStats.Total)" -ForegroundColor White
        Write-Host "  Encrypted: $($encryptionStats.Encrypted) ($encryptionPercentage%)" -ForegroundColor Green
        Write-Host "  Not Encrypted: $($encryptionStats.NotEncrypted)" -ForegroundColor $(if($encryptionStats.NotEncrypted -gt 0){"Red"}else{"Green"})
        Write-Host "  Unknown Status: $($encryptionStats.Unknown)" -ForegroundColor Yellow
        
        return $encryptionStats
        
    } catch {
        Write-Error "Failed to check device encryption compliance: $($_.Exception.Message)"
        return $null
    }
}

function New-OneDriveKnownFolderMovePolicy {
    param(
        [string]$PolicyName = "OneDrive Known Folder Move - eSIM Devices"
    )
    
    $policy = @{
        "@odata.type" = "#microsoft.graph.windows10GeneralConfiguration"
        displayName = $PolicyName
        description = "Automatically redirect Desktop, Documents, and Pictures to OneDrive for eSIM devices"
        oneDriveDisablePersonalSync = $false
        oneDriveRequireNetworkLocationForProfile = $true
        oneDriveBlockTelemetry = $false
    }
    
    try {
        $createdPolicy = New-MgDeviceManagementDeviceConfiguration -BodyParameter $policy
        Write-Host "+ Created OneDrive Policy: $PolicyName" -ForegroundColor Green
        
        # Assign to eSIM device groups
        $esimGroups = Get-MgGroup -Filter "startswith(displayName,'eSIM')"
        foreach ($group in $esimGroups) {
            $assignment = @{
                target = @{
                    "@odata.type" = "#microsoft.graph.groupAssignmentTarget"
                    groupId = $group.Id
                }
            }
            New-MgDeviceManagementDeviceConfigurationAssignment -DeviceConfigurationId $createdPolicy.Id -BodyParameter $assignment
        }
        
        return $createdPolicy
    } catch {
        Write-Error "Failed to create OneDrive policy: $($_.Exception.Message)"
        return $null
    }
}

function New-BitLockerEncryptionPolicy {
    param(
        [string]$PolicyName = "BitLocker Encryption - eSIM Windows Devices"
    )
    
    $policy = @{
        "@odata.type" = "#microsoft.graph.windows10EndpointProtectionConfiguration"
        displayName = $PolicyName
        description = "BitLocker encryption policy for Windows eSIM devices"
        bitLockerSystemDrivePolicy = @{
            encryptionMethod = "aesCbc256"
            startupAuthenticationRequired = $true
            startupAuthenticationBlockWithoutTpmChip = $false
            minimumPinLength = 6
            recoveryOptions = @{
                blockDataRecoveryAgent = $false
                recoveryPasswordUsage = "required"
                recoveryKeyUsage = "required"
                hideRecoveryOptions = $false
                enableRecoveryInformationSaveToStore = $true
                recoveryInformationToStore = "passwordAndKey"
                enableBitLockerAfterRecoveryInformationToStore = $true
            }
        }
        bitLockerFixedDrivePolicy = @{
            encryptionMethod = "aesCbc256"
            requireEncryptionForWriteAccess = $true
            recoveryOptions = @{
                blockDataRecoveryAgent = $false
                recoveryPasswordUsage = "required"
                recoveryKeyUsage = "required"
                hideRecoveryOptions = $false
                enableRecoveryInformationSaveToStore = $true
                recoveryInformationToStore = "passwordAndKey"
            }
        }
    }
    
    try {
        $createdPolicy = New-MgDeviceManagementDeviceConfiguration -BodyParameter $policy
        Write-Host "+ Created BitLocker Policy: $PolicyName" -ForegroundColor Green
        
        # Assign to Windows eSIM device groups
        $windowsGroups = Get-MgGroup -Filter "startswith(displayName,'eSIM') and contains(displayName,'Windows')"
        foreach ($group in $windowsGroups) {
            $assignment = @{
                target = @{
                    "@odata.type" = "#microsoft.graph.groupAssignmentTarget"
                    groupId = $group.Id
                }
            }
            New-MgDeviceManagementDeviceConfigurationAssignment -DeviceConfigurationId $createdPolicy.Id -BodyParameter $assignment
        }
        
        return $createdPolicy
    } catch {
        Write-Error "Failed to create BitLocker policy: $($_.Exception.Message)"
        return $null
    }
}

# Execute if run directly
if ($MyInvocation.InvocationName -ne '.') {
    Connect-MgGraph -Scopes "DeviceManagementConfiguration.ReadWrite.All", "DeviceManagementManagedDevices.Read.All"
    
    $onedriveResults = Test-OneDrivePolicies
    $bitlockerResults = Test-BitLockerPolicies
    $encryptionCompliance = Test-DeviceEncryptionCompliance
    
    Write-Host "`n=== Summary ===" -ForegroundColor Cyan
    Write-Host "OneDrive Issues: $($onedriveResults.Issues.Count)" -ForegroundColor $(if($onedriveResults.Issues.Count -gt 0){"Red"}else{"Green"})
    Write-Host "BitLocker Issues: $($bitlockerResults.Issues.Count)" -ForegroundColor $(if($bitlockerResults.Issues.Count -gt 0){"Red"}else{"Green"})
    Write-Host "Encryption Compliance: $([math]::Round(($encryptionCompliance.Encrypted / $encryptionCompliance.Total) * 100, 2))%" -ForegroundColor $(if($encryptionCompliance.Encrypted -eq $encryptionCompliance.Total){"Green"}else{"Yellow"})
    
    Disconnect-MgGraph
}