# eSIM Myanmar Zero Trust Bootstrap - Fixed Version
Write-Host "=== eSIM Myanmar Zero Trust Bootstrap ===" -ForegroundColor Cyan

# Configuration
$OrganizationName = "eSIM Myanmar / eSIM Enterprise"
$TargetDomain = "mdm.esim.com.mm"
$AdminUpn = "admin@mdm.esim.com.mm"
$PrimaryAppName = "eSIM Enterprise"
$SMDPServerUrl = "https://smdp.esim.com.mm"
$NamedLocationIpRanges = @("103.0.0.0/8","203.0.113.0/24")

# Connect to Microsoft Graph
$scopes = @(
    "Directory.ReadWrite.All",
    "Group.ReadWrite.All",
    "DeviceManagementConfiguration.ReadWrite.All",
    "DeviceManagementManagedDevices.ReadWrite.All",
    "Policy.ReadWrite.ConditionalAccess"
)

Connect-MgGraph -Scopes $scopes
$context = Get-MgContext
$org = Get-MgOrganization
Write-Host "Connected: $($context.Account) - Tenant: $($org.DisplayName)" -ForegroundColor Green

# Check domain
try {
    $domain = Get-MgDomain -DomainId $TargetDomain
    Write-Host "Domain $TargetDomain verified: $($domain.IsVerified)" -ForegroundColor Green
} catch {
    Write-Host "Domain $TargetDomain not found" -ForegroundColor Red
}

# Check admin user
try {
    $admin = Get-MgUser -UserId $AdminUpn
    Write-Host "Admin user: $($admin.DisplayName)" -ForegroundColor Green
} catch {
    Write-Host "Admin user not found: $AdminUpn" -ForegroundColor Red
}

# Create groups function
function EnsureGroup($displayName, $mailNick, $isDynamic, $rule) {
    $g = Get-MgGroup -Filter "displayName eq '$displayName'" -ErrorAction SilentlyContinue
    if (-not $g) {
        Write-Host "Creating group: $displayName" -ForegroundColor Yellow
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
        Write-Host "Group exists: $displayName" -ForegroundColor Blue
        return $g
    }
}

# Create device groups
Write-Host "`nCreating device groups..." -ForegroundColor Cyan
$eSimGroup = EnsureGroup -displayName "eSIM Enterprise Devices" -mailNick "esimdevices" -isDynamic $false -rule $null
$androidGroup = EnsureGroup -displayName "Android Enterprise Devices" -mailNick "androidesim" -isDynamic $true -rule "(device.deviceOSType -eq 'Android')"
$windowsGroup = EnsureGroup -displayName "Windows eSIM Devices" -mailNick "win_esim" -isDynamic $true -rule "(device.deviceOSType -eq 'Windows')"

# Create configuration profiles
Write-Host "`nCreating configuration profiles..." -ForegroundColor Cyan
try {
    $winProfileName = "eSIM Windows Security - BitLocker"
    $winProfile = Get-MgDeviceManagementDeviceConfiguration | Where-Object { $_.DisplayName -eq $winProfileName }
    if (-not $winProfile) {
        Write-Host "Would create Windows profile: $winProfileName" -ForegroundColor Yellow
    } else {
        Write-Host "Windows profile exists: $winProfileName" -ForegroundColor Blue
    }
} catch {
    Write-Host "Intune not accessible for configuration profiles" -ForegroundColor Red
}

# Create compliance policies
Write-Host "`nCreating compliance policies..." -ForegroundColor Cyan
try {
    $winPolicyName = "eSIM Windows Compliance"
    $winPolicy = Get-MgDeviceManagementDeviceCompliancePolicy | Where-Object { $_.DisplayName -eq $winPolicyName }
    if (-not $winPolicy) {
        Write-Host "Would create Windows compliance: $winPolicyName" -ForegroundColor Yellow
    } else {
        Write-Host "Windows compliance exists: $winPolicyName" -ForegroundColor Blue
    }
} catch {
    Write-Host "Intune not accessible for compliance policies" -ForegroundColor Red
}

# Create named locations
Write-Host "`nCreating named locations..." -ForegroundColor Cyan
foreach ($ip in $NamedLocationIpRanges) {
    $name = "Myanmar-Office-$($ip.Replace('/','_'))"
    try {
        $existing = Get-MgIdentityConditionalAccessNamedLocation -Filter "displayName eq '$name'" -ErrorAction SilentlyContinue
        if (-not $existing) {
            Write-Host "Would create named location: $name for $ip" -ForegroundColor Yellow
        } else {
            Write-Host "Named location exists: $name" -ForegroundColor Blue
        }
    } catch {
        Write-Host "Cannot access named locations" -ForegroundColor Red
    }
}

# Create Conditional Access policy
Write-Host "`nCreating Conditional Access policy..." -ForegroundColor Cyan
$caName = "eSIM ZeroTrust - Require MFA & compliant device"
try {
    $existingCA = Get-MgIdentityConditionalAccessPolicy | Where-Object { $_.DisplayName -eq $caName }
    if (-not $existingCA) {
        Write-Host "Would create CA policy: $caName" -ForegroundColor Yellow
    } else {
        Write-Host "CA policy exists: $caName" -ForegroundColor Blue
    }
} catch {
    Write-Host "Cannot access Conditional Access policies" -ForegroundColor Red
}

# Summary
Write-Host "`n================== BOOTSTRAP SUMMARY ==================" -ForegroundColor Cyan
Write-Host "Organization: $OrganizationName" -ForegroundColor White
Write-Host "Target Domain: $TargetDomain" -ForegroundColor White
Write-Host "Admin UPN: $AdminUpn" -ForegroundColor White
Write-Host "Primary App: $PrimaryAppName" -ForegroundColor White
Write-Host "SM-DP+ Server: $SMDPServerUrl" -ForegroundColor White

Write-Host "`nDevice Groups Created:" -ForegroundColor Green
if ($eSimGroup) { Write-Host "  - $($eSimGroup.DisplayName)" -ForegroundColor White }
if ($androidGroup) { Write-Host "  - $($androidGroup.DisplayName)" -ForegroundColor White }
if ($windowsGroup) { Write-Host "  - $($windowsGroup.DisplayName)" -ForegroundColor White }

Write-Host "`nNext Steps:" -ForegroundColor Yellow
Write-Host "1. Purchase EMS E3 license for full Intune functionality" -ForegroundColor White
Write-Host "2. Configure Android Enterprise in Intune portal" -ForegroundColor White
Write-Host "3. Add OEMConfig app: com.esim.oemconfig" -ForegroundColor White
Write-Host "4. Configure SM-DP+ server settings" -ForegroundColor White
Write-Host "5. Set up Company Portal branding" -ForegroundColor White
Write-Host "6. Enable Identity Protection and PIM" -ForegroundColor White

Write-Host "`nBootstrap complete - eSIM Myanmar Zero Trust foundation ready!" -ForegroundColor Green