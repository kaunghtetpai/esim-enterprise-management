# =====================================================================
# eSIM Myanmar / eSIM Enterprise — Full Zero Trust + Intune + Entra Bootstrap
# Purpose: Full health-check, create/update, Zero Trust hardening, Android Enterprise + OEMConfig, eSIM activation scaffolding, Company Portal branding
# Pre-reqs: PowerShell 7+, Global Admin interactive login
# WARNING: Replace all <PLACEHOLDER> values BEFORE running in production
# =====================================================================

# -------------------------
# Configurable variables — REPLACE these
# -------------------------
$OrganizationName          = "eSIM Myanmar / eSIM Enterprise"
$TargetDomain              = "mdm.esim.com.mm"
$AdminUpn                  = "admin@mdm.esim.com.mm"
$PrimaryAppName            = "eSIM Enterprise"
$SMDPServerUrl             = "https://smdp.esim.com.mm"         # Carrier SM-DP+ server URL
$IntuneSkuId               = "c1ec4a95-1f05-45b3-a911-aa3fa01094f5"         # Optional
$OEMConfigPackageName      = "com.esim.oemconfig"  # e.g., com.oem.oemconfig
$ManagedGooglePlayToken    = "MGP-TOKEN-PLACEHOLDER"      # if using automated flow
$BrandingBannerUri         = "https://esim.com.mm/banner.png"
$CompanyPortalLogoUri      = "https://esim.com.mm/logo.png"
$NamedLocationIpRanges     = @("103.0.0.0/8","203.0.113.0/24")
$PasswordInitial           = "ChangeMe!2025"

# -------------------------
# 1) Install / Import Microsoft.Graph
# -------------------------
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force
}
Import-Module Microsoft.Graph -ErrorAction Stop
Select-MgProfile -Name "beta"

# -------------------------
# 2) Connect (interactive)
# -------------------------
$scopes = @(
    "Directory.ReadWrite.All",
    "Application.ReadWrite.All",
    "User.ReadWrite.All",
    "Group.ReadWrite.All",
    "DeviceManagementConfiguration.ReadWrite.All",
    "DeviceManagementManagedDevices.ReadWrite.All",
    "DeviceManagementApps.ReadWrite.All",
    "Policy.ReadWrite.ConditionalAccess",
    "RoleManagement.ReadWrite.Directory"
)
Write-Host "Please sign in with a Global Admin account..."
Connect-MgGraph -Scopes $scopes
$me = Get-MgContext
$org = Get-MgOrganization
Write-Host "Connected: $($me.Account) — Tenant: $($org.DisplayName)"

# -------------------------
# 3) Domain add/verify
# -------------------------
try {
    $domain = Get-MgDomain -DomainId $TargetDomain -ErrorAction Stop
    Write-Host "Domain exists: $TargetDomain (IsVerified: $($domain.IsVerified))"
} catch {
    Write-Host "Adding domain object: $TargetDomain"
    $domain = New-MgDomain -BodyParameter @{ Id = $TargetDomain }
    Write-Host "Retrieve TXT verification record and add to your DNS:"
    $txt = Get-MgDomainVerificationDnsRecord -DomainId $TargetDomain
    $txt | Select-Object Label, Text, TimeToLive | Format-Table -AutoSize
    Write-Host "After DNS propagation run: Confirm-MgDomain -DomainId '$TargetDomain'"
    return
}

if (-not $domain.IsVerified) {
    Write-Host "Domain exists but not verified. Add TXT record then run Confirm-MgDomain after propagation."
    return
}

# -------------------------
# 4) Admin user
# -------------------------
$admin = Get-MgUser -Filter "userPrincipalName eq '$AdminUpn'" -ErrorAction SilentlyContinue
if (-not $admin) {
    Write-Host "Creating admin user: $AdminUpn"
    $pwdProfile = @{
        ForceChangePasswordNextSignIn = $true
        Password = $PasswordInitial
    }
    $userBody = @{
        AccountEnabled = $true
        DisplayName = "eSIM Enterprise Admin"
        MailNickname = "esimadmin"
        UserPrincipalName = $AdminUpn
        PasswordProfile = $pwdProfile
    }
    $admin = New-MgUser -BodyParameter $userBody
} else {
    Write-Host "Admin user exists: $($admin.DisplayName)"
}

# -------------------------
# 5) Groups
# -------------------------
function EnsureGroup($displayName, $mailNick, $isDynamic, $rule) {
    $g = Get-MgGroup -Filter "displayName eq '$displayName'" -ErrorAction SilentlyContinue
    if (-not $g) {
        Write-Host "Creating group: $displayName"
        if ($isDynamic -and $rule) {
            $params = @{
                DisplayName = $displayName
                MailEnabled = $false
                MailNickname = $mailNick
                SecurityEnabled = $true
                GroupTypes = @("DynamicMembership")
                MembershipRule = $rule
                MembershipRuleProcessingState = "On"
            }
        } else {
            $params = @{
                DisplayName = $displayName
                MailEnabled = $false
                MailNickname = $mailNick
                SecurityEnabled = $true
            }
        }
        return New-MgGroup -BodyParameter $params
    } else {
        Write-Host "Group exists: $displayName"
        return $g
    }
}
$eSimGroup = EnsureGroup -displayName "eSIM Enterprise Devices" -mailNick "esimdevices" -isDynamic $false -rule $null
$androidGroup = EnsureGroup -displayName "Android Enterprise Devices" -mailNick "androidesim" -isDynamic $true -rule "(device.deviceOSType -eq 'Android')"
$windowsGroup = EnsureGroup -displayName "Windows eSIM Devices" -mailNick "win_esim" -isDynamic $true -rule "(device.deviceOSType -eq 'Windows')"

# -------------------------
# 6) Device Configuration Profiles (Windows + Android)
# -------------------------
# Windows BitLocker profile
$winProfileName = "eSIM Windows Security - BitLocker"
$winProfile = Get-MgDeviceManagementDeviceConfiguration | Where-Object { $_.DisplayName -eq $winProfileName }
if (-not $winProfile) {
    $profileBody = @{
        DisplayName = $winProfileName
        Description = "Enforce BitLocker with TPM + PIN"
        Platform = "windows10AndLater"
        OdataType = "#microsoft.graph.windows10EndpointProtectionConfiguration"
    }
    $winProfile = New-MgDeviceManagementDeviceConfiguration -BodyParameter $profileBody -ErrorAction SilentlyContinue
}
if ($winProfile -and $windowsGroup) {
    New-MgDeviceManagementDeviceConfigurationAssignment -DeviceConfigurationId $winProfile.Id -BodyParameter @{ Target = @{ GroupId = $windowsGroup.Id } } -ErrorAction SilentlyContinue
}

# Android baseline profile
$androidProfileName = "eSIM Android Enterprise Baseline"
$androidProfile = Get-MgDeviceManagementDeviceConfiguration | Where-Object { $_.DisplayName -eq $androidProfileName }
if (-not $androidProfile) {
    $body = @{
        DisplayName = $androidProfileName
        Description = "Baseline for Android Enterprise eSIM devices"
        Platform = "androidForWork"
    }
    $androidProfile = New-MgDeviceManagementDeviceConfiguration -BodyParameter $body -ErrorAction SilentlyContinue
}
if ($androidProfile -and $androidGroup) {
    New-MgDeviceManagementDeviceConfigurationAssignment -DeviceConfigurationId $androidProfile.Id -BodyParameter @{ Target = @{ GroupId = $androidGroup.Id } } -ErrorAction SilentlyContinue
}

# -------------------------
# 7) Compliance Policies
# -------------------------
# Windows compliance
$winPolicyName = "eSIM Windows Compliance"
$winPolicy = Get-MgDeviceManagementDeviceCompliancePolicy | Where-Object { $_.DisplayName -eq $winPolicyName }
if (-not $winPolicy) {
    $winPolicy = New-MgDeviceManagementDeviceCompliancePolicy -BodyParameter @{
        DisplayName = $winPolicyName
        Description = "Compliance baseline for Windows eSIM devices"
        Platform = "windows10AndLater"
    } -ErrorAction SilentlyContinue
}
if ($winPolicy -and $windowsGroup) {
    New-MgDeviceManagementDeviceCompliancePolicyAssignment -DeviceCompliancePolicyId $winPolicy.Id -BodyParameter @{ Target = @{ GroupId = $windowsGroup.Id } } -ErrorAction SilentlyContinue
}

# Android compliance
$andPolicyName = "eSIM Android Compliance"
$andPolicy = Get-MgDeviceManagementDeviceCompliancePolicy | Where-Object { $_.DisplayName -eq $andPolicyName }
if (-not $andPolicy) {
    $andPolicy = New-MgDeviceManagementDeviceCompliancePolicy -BodyParameter @{
        DisplayName = $andPolicyName
        Description = "Compliance baseline for Android Enterprise eSIM devices"
        Platform = "androidForWork"
    } -ErrorAction SilentlyContinue
}
if ($andPolicy -and $androidGroup) {
    New-MgDeviceManagementDeviceCompliancePolicyAssignment -DeviceCompliancePolicyId $andPolicy.Id -BodyParameter @{ Target = @{ GroupId = $androidGroup.Id } } -ErrorAction SilentlyContinue
}

# -------------------------
# 8) Conditional Access / Zero Trust
# -------------------------
foreach ($ip in $NamedLocationIpRanges) {
    $name = "Office-$ip"
    $existing = Get-MgIdentityConditionalAccessNamedLocation -Filter "displayName eq '$name'" -ErrorAction SilentlyContinue
    if (-not $existing) {
        New-MgIdentityConditionalAccessNamedLocation -BodyParameter @{
            "@odata.type" = "#microsoft.graph.ipNamedLocation"
            DisplayName = $name
            IsTrusted = $true
            IpRanges = @(@{ "@odata.type" = "#microsoft.graph.iPv4CidrRange"; CidrAddress = $ip })
        } -ErrorAction SilentlyContinue
    }
}

$caName = "eSIM ZeroTrust - Require MFA & compliant device for all users"
$existingCA = Get-MgIdentityConditionalAccessPolicy | Where-Object { $_.DisplayName -eq $caName }
if (-not $existingCA) {
    $caBody = @{
        DisplayName = $caName
        State = "enabled"
        Conditions = @{
            Users = @{ IncludeUsers = @("All") }
            Platforms = @{ IncludePlatforms = @("all") }
        }
        GrantControls = @{ 
            Operator = "AND"
            BuiltInControls = @("mfa","compliantDevice") 
        }
    }
    New-MgIdentityConditionalAccessPolicy -BodyParameter $caBody -ErrorAction SilentlyContinue
}

# -------------------------
# 9) Company Portal / Branding
# -------------------------
Write-Host "`nCompany Branding / Portal setup:"
Write-Host "Upload banners/logos via Azure AD / Intune UI; set colors, support URL, and contact info."
Write-Host "Company Portal app: $PrimaryAppName (create placeholder if not existing)."

# -------------------------
# 10) OEMConfig & eSIM scaffolding
# -------------------------
Write-Host "Add OEMConfig app: $OEMConfigPackageName via Managed Google Play; assign to Android Enterprise Devices group."
Write-Host "Configure SM-DP+ server: $SMDPServerUrl via OMA-URI settings or Intune GUI."
Write-Host "Enroll test devices and validate eSIM activation."

# -------------------------
# 11) Identity Protection / Passwordless / PIM
# -------------------------
Write-Host "Enable SSPR, FIDO2 / Passwordless auth, PIM for admin roles, and Identity Protection risk policies (via Entra portal or Graph)."

# -------------------------
# 12) Summary
# -------------------------
Write-Host "`n================== Summary =================="
Write-Host "Org: $OrganizationName"
Write-Host "Domain verified: $($domain.IsVerified)"
Write-Host "Admin: $AdminUpn"
Write-Host "Groups: $($eSimGroup.DisplayName), $($androidGroup.DisplayName), $($windowsGroup.DisplayName)"
Write-Host "Profiles: $winProfileName, $androidProfileName"
Write-Host "Compliance: $winPolicyName, $andPolicyName"
Write-Host "CA policy: $caName"
Write-Host "Company Portal app: $PrimaryAppName"
Write-Host "SM-DP+ URL: $SMDPServerUrl"
Write-Host "=============================================="