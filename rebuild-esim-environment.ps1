# Rebuild Clean eSIM Environment for MDM.esim.com.mm

Connect-MgGraph -Scopes @(
    "DeviceManagementConfiguration.ReadWrite.All",
    "Group.ReadWrite.All",
    "Policy.ReadWrite.ConditionalAccess"
)

Write-Host "=== REBUILDING ESIM ENVIRONMENT ===" -ForegroundColor Cyan

# Phase 1: Create eSIM Device Groups
Write-Host "`n1. Creating eSIM Device Groups..." -ForegroundColor Yellow

$carriers = @("MPT", "ATOM", "U9", "MYTEL")
foreach ($carrier in $carriers) {
    $groupParams = @{
        DisplayName = "eSIM Devices - $carrier"
        Description = "Dynamic group for $carrier eSIM devices"
        MailNickname = "esim$($carrier.ToLower())devices"
        GroupTypes = @("DynamicMembership")
        MembershipRule = "(device.deviceModel -contains `"eSIM`") and (device.extensionAttribute1 -eq `"$carrier`")"
        MembershipRuleProcessingState = "On"
        MailEnabled = $false
        SecurityEnabled = $true
    }
    
    try {
        New-MgGroup -BodyParameter $groupParams | Out-Null
        Write-Host "+ Created: eSIM Devices - $carrier" -ForegroundColor Green
    } catch {
        Write-Host "- Failed: eSIM Devices - $carrier" -ForegroundColor Red
    }
}

# Create admin and general groups
$adminGroup = @{
    DisplayName = "Admins - eSIM Enterprise"
    Description = "eSIM Enterprise Administrators"
    MailNickname = "esimadmins"
    GroupTypes = @()
    MailEnabled = $false
    SecurityEnabled = $true
}

$deviceGroup = @{
    DisplayName = "Devices - eSIM"
    Description = "All eSIM capable devices"
    MailNickname = "esimdevices"
    GroupTypes = @("DynamicMembership")
    MembershipRule = "(device.deviceModel -contains `"eSIM`")"
    MembershipRuleProcessingState = "On"
    MailEnabled = $false
    SecurityEnabled = $true
}

New-MgGroup -BodyParameter $adminGroup | Out-Null
New-MgGroup -BodyParameter $deviceGroup | Out-Null
Write-Host "+ Created admin and device groups" -ForegroundColor Green

# Phase 2: Create Baseline Compliance Policies
Write-Host "`n2. Creating Baseline Compliance Policies..." -ForegroundColor Yellow

# Windows compliance
$windowsCompliance = @{
    "@odata.type" = "#microsoft.graph.windows10CompliancePolicy"
    displayName = "eSIM Windows Baseline Compliance"
    description = "Baseline compliance for Windows eSIM devices"
    passwordRequired = $true
    passwordMinimumLength = 8
    passwordRequiredType = "alphanumeric"
    osMinimumVersion = "10.0.19041"
    bitLockerEnabled = $true
    secureBootEnabled = $true
    storageRequireEncryption = $true
}

# iOS compliance
$iosCompliance = @{
    "@odata.type" = "#microsoft.graph.iosCompliancePolicy"
    displayName = "eSIM iOS Baseline Compliance"
    description = "Baseline compliance for iOS eSIM devices"
    passcodeRequired = $true
    passcodeMinimumLength = 6
    passcodeRequiredType = "alphanumeric"
    osMinimumVersion = "15.0"
    deviceThreatProtectionEnabled = $true
}

# Android compliance
$androidCompliance = @{
    "@odata.type" = "#microsoft.graph.androidCompliancePolicy"
    displayName = "eSIM Android Baseline Compliance"
    description = "Baseline compliance for Android eSIM devices"
    passwordRequired = $true
    passwordMinimumLength = 6
    passwordRequiredType = "alphanumeric"
    osMinimumVersion = "10.0"
    storageRequireEncryption = $true
    securityBlockJailbrokenDevices = $true
}

$policies = @($windowsCompliance, $iosCompliance, $androidCompliance)

foreach ($policy in $policies) {
    try {
        New-MgDeviceManagementDeviceCompliancePolicy -BodyParameter $policy | Out-Null
        Write-Host "+ Created: $($policy.displayName)" -ForegroundColor Green
    } catch {
        Write-Host "- Failed: $($policy.displayName)" -ForegroundColor Red
    }
}

# Phase 3: Create Zero Trust Conditional Access
Write-Host "`n3. Creating Zero Trust Conditional Access..." -ForegroundColor Yellow

$zeroTrustPolicy = @{
    displayName = "eSIM Zero Trust - Require Compliant Device + MFA"
    state = "enabled"
    conditions = @{
        applications = @{
            includeApplications = @("All")
        }
        users = @{
            includeGroups = @((Get-MgGroup -Filter "displayName eq 'Devices - eSIM'").Id)
        }
        platforms = @{
            includePlatforms = @("windows", "iOS", "android")
        }
    }
    grantControls = @{
        operator = "AND"
        builtInControls = @("mfa", "compliantDevice")
    }
}

try {
    New-MgIdentityConditionalAccessPolicy -BodyParameter $zeroTrustPolicy | Out-Null
    Write-Host "+ Created Zero Trust policy" -ForegroundColor Green
} catch {
    Write-Host "- Failed Zero Trust policy" -ForegroundColor Red
}

Write-Host "`n=== REBUILD COMPLETE ===" -ForegroundColor Green
Write-Host "Environment ready for eSIM Profile Management integration" -ForegroundColor White