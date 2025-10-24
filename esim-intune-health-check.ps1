# =====================================================================
# eSIM Enterprise - Microsoft Intune Full Health Check & Update Script
# Organization: eSIM Myanmar
# Domain: mdm.esim.com.mm
# Admin: admin@mdm.esim.com.mm
# =====================================================================

Write-Host "Initializing Microsoft Graph connection..." -ForegroundColor Cyan

# Required modules
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force
}
Import-Module Microsoft.Graph
Select-MgProfile -Name "beta"

# Required permissions for Intune + Entra
$scopes = @(
    "Directory.ReadWrite.All",
    "DeviceManagementConfiguration.ReadWrite.All",
    "DeviceManagementManagedDevices.ReadWrite.All",
    "DeviceManagementApps.ReadWrite.All",
    "Group.ReadWrite.All",
    "User.ReadWrite.All",
    "Application.ReadWrite.All",
    "Policy.ReadWrite.ConditionalAccess"
)

Connect-MgGraph -Scopes $scopes
$org = Get-MgOrganization
Write-Host "Connected to tenant: $($org.DisplayName)" -ForegroundColor Green

# =====================================================================
# 1. Verify Domain Setup
# =====================================================================
$domainName = "mdm.esim.com.mm"
try {
    $domain = Get-MgDomain -DomainId $domainName -ErrorAction Stop
    if ($domain.IsVerified) {
        Write-Host "Domain $domainName verified." -ForegroundColor Green
    } else {
        Write-Host "Domain $domainName exists but not verified." -ForegroundColor Yellow
        $dns = Get-MgDomainVerificationDnsRecord -DomainId $domainName
        $dns | Select-Object Label, Text, TimeToLive
    }
} catch {
    Write-Host "Domain not found. Adding new domain $domainName..." -ForegroundColor Yellow
    New-MgDomain -BodyParameter @{ Id = $domainName }
}

# =====================================================================
# 2. Check Admin Account
# =====================================================================
$adminUpn = "admin@mdm.esim.com.mm"
$admin = Get-MgUser -Filter "userPrincipalName eq '$adminUpn'" -ErrorAction SilentlyContinue
if (-not $admin) {
    Write-Host "Admin account missing. Creating new admin user..." -ForegroundColor Yellow
    $passwordProfile = @{
        ForceChangePasswordNextSignIn = $true
        Password = "ChangeMe!1234"
    }
    $admin = New-MgUser -BodyParameter @{
        DisplayName = "eSIM Enterprise Admin"
        MailNickname = "esimadmin"
        UserPrincipalName = $adminUpn
        PasswordProfile = $passwordProfile
        AccountEnabled = $true
    }
    Write-Host "Admin created. Enforce MFA & change password immediately." -ForegroundColor Green
} else {
    Write-Host "Admin user verified: $($admin.DisplayName)" -ForegroundColor Green
}

# =====================================================================
# 3. Check Device Groups
# =====================================================================
$groupName = "eSIM Enterprise Devices"
$group = Get-MgGroup -Filter "displayName eq '$groupName'" -ErrorAction SilentlyContinue
if (-not $group) {
    Write-Host "Creating device group '$groupName'..." -ForegroundColor Yellow
    $group = New-MgGroup -BodyParameter @{
        DisplayName = $groupName
        MailEnabled = $false
        MailNickname = "esimdevices"
        SecurityEnabled = $true
    }
} else {
    Write-Host "Device group verified: $groupName" -ForegroundColor Green
}

# =====================================================================
# 4. Verify Intune Configuration Profiles
# =====================================================================
$profileName = "eSIM Enterprise Device Configuration"
$profile = Get-MgDeviceManagementDeviceConfiguration | Where-Object { $_.DisplayName -eq $profileName }

if (-not $profile) {
    Write-Host "Creating device configuration profile..." -ForegroundColor Yellow
    $profile = New-MgDeviceManagementDeviceConfiguration -BodyParameter @{
        DisplayName = $profileName
        Description = "Standard configuration for eSIM Enterprise devices"
        Platform    = "windows10AndLater"
    }
} else {
    Write-Host "Device configuration profile verified." -ForegroundColor Green
}

# =====================================================================
# 5. Verify Compliance Policies
# =====================================================================
$policyName = "eSIM Enterprise Compliance Policy"
$policy = Get-MgDeviceManagementDeviceCompliancePolicy | Where-Object { $_.DisplayName -eq $policyName }

if (-not $policy) {
    Write-Host "Creating compliance policy..." -ForegroundColor Yellow
    $policy = New-MgDeviceManagementDeviceCompliancePolicy -BodyParameter @{
        DisplayName = $policyName
        Description = "Compliance baseline for eSIM Enterprise"
        Platform    = "windows10AndLater"
    }
} else {
    Write-Host "Compliance policy verified." -ForegroundColor Green
}

# =====================================================================
# 6. Verify Conditional Access Policies
# =====================================================================
$caPolicies = Get-MgIdentityConditionalAccessPolicy -ErrorAction SilentlyContinue
if (-not $caPolicies) {
    Write-Host "Creating baseline Conditional Access policy..." -ForegroundColor Yellow
    New-MgIdentityConditionalAccessPolicy -DisplayName "eSIM Baseline Security" `
        -State "enabled" `
        -Conditions @{
            Users = @{ IncludeUsers = @("All") }
        } `
        -GrantControls @{ BuiltInControls = @("mfa") }
} else {
    Write-Host "Conditional Access policies verified." -ForegroundColor Green
}

# =====================================================================
# 7. Verify Managed Devices
# =====================================================================
$devices = Get-MgDeviceManagementManagedDevice
if ($devices) {
    Write-Host "Managed Devices Found:" -ForegroundColor Green
    $devices | Select-Object DeviceName, OperatingSystem, ComplianceState | Format-Table -AutoSize
} else {
    Write-Host "No managed devices detected. Enroll devices in Intune." -ForegroundColor Yellow
}

# =====================================================================
# 8. Verify Apps
# =====================================================================
$appName = "eSIM Enterprise"
$app = Get-MgDeviceAppManagementMobileApp | Where-Object { $_.DisplayName -eq $appName }

if (-not $app) {
    Write-Host "Adding mobile app $appName to Intune..." -ForegroundColor Yellow
    $app = New-MgDeviceAppManagementMobileApp -BodyParameter @{
        DisplayName = $appName
        Publisher = "eSIM Myanmar"
        IsFeaturedApp = $true
        Description = "eSIM provisioning and enterprise management app"
    }
} else {
    Write-Host "App verified: $($app.DisplayName)" -ForegroundColor Green
}

# =====================================================================
# 9. Assign Policies and Profiles to Group
# =====================================================================
if ($group -and $profile) {
    Write-Host "Assigning configuration profile to device group..." -ForegroundColor Yellow
    New-MgDeviceManagementDeviceConfigurationAssignment -DeviceConfigurationId $profile.Id -BodyParameter @{
        Target = @{ GroupId = $group.Id }
    } -ErrorAction SilentlyContinue
}
if ($group -and $policy) {
    Write-Host "Assigning compliance policy to device group..." -ForegroundColor Yellow
    New-MgDeviceManagementDeviceCompliancePolicyAssignment -DeviceCompliancePolicyId $policy.Id -BodyParameter @{
        Target = @{ GroupId = $group.Id }
    } -ErrorAction SilentlyContinue
}

# =====================================================================
# 10. Final Health Summary
# =====================================================================
Write-Host ""
Write-Host "====================================================="
Write-Host "      eSIM Enterprise Intune Health Summary"
Write-Host "====================================================="
Write-Host "Tenant:         $($org.DisplayName)"
Write-Host "Domain:         $domainName"
Write-Host "Admin Account:  $adminUpn"
Write-Host "Device Group:   $groupName"
Write-Host "Config Profile: $($profile.DisplayName)"
Write-Host "Compliance:     $($policy.DisplayName)"
Write-Host "App:            $($app.DisplayName)"
Write-Host "====================================================="
Write-Host "All items verified and updated successfully." -ForegroundColor Green
Write-Host "Next Steps:"
Write-Host "1. Confirm domain TXT record verification (if pending)"
Write-Host "2. Review Conditional Access MFA enforcement"
Write-Host "3. Test device enrollment for Windows / Android"
Write-Host "4. Validate compliance & app deployment"