# eSIM Compliance and Security Policies

# Windows compliance policy
$windowsCompliance = @{
    "@odata.type" = "#microsoft.graph.windows10CompliancePolicy"
    displayName = "eSIM Windows Compliance"
    description = "Compliance policy for Windows devices with eSIM"
    passwordRequired = $true
    passwordMinimumLength = 8
    passwordRequiredType = "alphanumeric"
    osMinimumVersion = "10.0.19041"
    osMaximumVersion = "10.0.99999"
    bitLockerEnabled = $true
    secureBootEnabled = $true
    codeIntegrityEnabled = $true
    storageRequireEncryption = $true
}

# iOS compliance policy
$iosCompliance = @{
    "@odata.type" = "#microsoft.graph.iosCompliancePolicy"
    displayName = "eSIM iOS Compliance"
    description = "Compliance policy for iOS devices with eSIM"
    passcodeRequired = $true
    passcodeMinimumLength = 6
    passcodeRequiredType = "alphanumeric"
    osMinimumVersion = "14.0"
    osMaximumVersion = "99.0"
    deviceThreatProtectionEnabled = $true
    deviceThreatProtectionRequiredSecurityLevel = "medium"
}

# Android compliance policy
$androidCompliance = @{
    "@odata.type" = "#microsoft.graph.androidCompliancePolicy"
    displayName = "eSIM Android Compliance"
    description = "Compliance policy for Android devices with eSIM"
    passwordRequired = $true
    passwordMinimumLength = 6
    passwordRequiredType = "alphanumeric"
    osMinimumVersion = "8.0"
    osMaximumVersion = "99.0"
    storageRequireEncryption = $true
    securityBlockJailbrokenDevices = $true
}

$policies = @($windowsCompliance, $iosCompliance, $androidCompliance)

foreach ($policy in $policies) {
    try {
        $createdPolicy = New-MgDeviceManagementDeviceCompliancePolicy -BodyParameter $policy
        Write-Host "Created compliance policy: $($policy.displayName)" -ForegroundColor Green
        
        # Assign to all eSIM devices
        $assignment = @{
            target = @{
                "@odata.type" = "#microsoft.graph.allDevicesAssignmentTarget"
            }
        }
        New-MgDeviceManagementDeviceCompliancePolicyAssignment -DeviceCompliancePolicyId $createdPolicy.Id -BodyParameter $assignment
    } catch {
        Write-Warning "Failed to create policy: $($policy.displayName)"
    }
}