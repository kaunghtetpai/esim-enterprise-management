# Complete System Error Check & Update - All Microsoft Services
Write-Host "=== Complete Microsoft System Check ===" -ForegroundColor Cyan

# Connect with all required scopes
Connect-MgGraph -Scopes @(
    "Directory.ReadWrite.All",
    "User.ReadWrite.All", 
    "Group.ReadWrite.All",
    "Application.ReadWrite.All",
    "DeviceManagementConfiguration.ReadWrite.All",
    "DeviceManagementManagedDevices.ReadWrite.All",
    "Policy.ReadWrite.ConditionalAccess",
    "Organization.ReadWrite.All"
)

Write-Host "✅ Connected to Microsoft Graph" -ForegroundColor Green

# 1. TENANT CHECK
Write-Host "`n1. TENANT STATUS" -ForegroundColor Yellow
$org = Get-MgOrganization
$context = Get-MgContext
Write-Host "Tenant ID: $($context.TenantId)" -ForegroundColor White
Write-Host "Account: $($context.Account)" -ForegroundColor White
Write-Host "Organization: $($org.DisplayName)" -ForegroundColor White

# 2. DOMAIN CHECK
Write-Host "`n2. DOMAIN STATUS" -ForegroundColor Yellow
$domains = Get-MgDomain
foreach ($domain in $domains) {
    $status = if ($domain.IsVerified) { "✅ Verified" } else { "❌ Pending" }
    Write-Host "$($domain.Id): $status" -ForegroundColor White
}

# 3. ADMIN ACCOUNT CHECK
Write-Host "`n3. ADMIN ACCOUNT STATUS" -ForegroundColor Yellow
try {
    $admin = Get-MgUser -UserId "admin@mdm.esim.com.mm"
    Write-Host "✅ Admin: $($admin.DisplayName)" -ForegroundColor Green
    Write-Host "   UPN: $($admin.UserPrincipalName)" -ForegroundColor White
    Write-Host "   Enabled: $($admin.AccountEnabled)" -ForegroundColor White
} catch {
    Write-Host "❌ Admin account not found" -ForegroundColor Red
}

# 4. LICENSE CHECK
Write-Host "`n4. LICENSE STATUS" -ForegroundColor Yellow
$licenses = Get-MgSubscribedSku
foreach ($license in $licenses) {
    $available = $license.PrepaidUnits.Enabled - $license.ConsumedUnits
    Write-Host "$($license.SkuPartNumber): $available/$($license.PrepaidUnits.Enabled)" -ForegroundColor White
}

# 5. GROUPS CHECK
Write-Host "`n5. DEVICE GROUPS STATUS" -ForegroundColor Yellow
$groups = Get-MgGroup -Filter "startswith(displayName,'eSIM')"
Write-Host "eSIM Groups: $($groups.Count)" -ForegroundColor White
foreach ($group in $groups) {
    Write-Host "  ✅ $($group.DisplayName)" -ForegroundColor Green
}

# 6. APPLICATIONS CHECK
Write-Host "`n6. APPLICATION STATUS" -ForegroundColor Yellow
$apps = Get-MgApplication -Filter "startswith(displayName,'eSIM')"
Write-Host "eSIM Apps: $($apps.Count)" -ForegroundColor White
foreach ($app in $apps) {
    Write-Host "  ✅ $($app.DisplayName): $($app.AppId)" -ForegroundColor Green
}

# 7. INTUNE SERVICE CHECK
Write-Host "`n7. INTUNE SERVICE STATUS" -ForegroundColor Yellow
try {
    $devices = Get-MgDeviceManagementManagedDevice -ErrorAction Stop
    Write-Host "✅ Intune accessible: $($devices.Count) devices" -ForegroundColor Green
} catch {
    Write-Host "❌ Intune not accessible: $($_.Exception.Message)" -ForegroundColor Red
}

# 8. CONDITIONAL ACCESS CHECK
Write-Host "`n8. CONDITIONAL ACCESS STATUS" -ForegroundColor Yellow
try {
    $caPolicies = Get-MgIdentityConditionalAccessPolicy -ErrorAction Stop
    Write-Host "✅ CA Policies: $($caPolicies.Count)" -ForegroundColor Green
} catch {
    Write-Host "❌ CA not accessible: $($_.Exception.Message)" -ForegroundColor Red
}

# 9. AZURE SUBSCRIPTION CHECK
Write-Host "`n9. AZURE SUBSCRIPTION STATUS" -ForegroundColor Yellow
try {
    # Check if Azure PowerShell is available
    if (Get-Module -ListAvailable -Name Az.Accounts) {
        Import-Module Az.Accounts -Force
        $azContext = Get-AzContext
        if ($azContext) {
            Write-Host "✅ Azure: $($azContext.Subscription.Name)" -ForegroundColor Green
        } else {
            Write-Host "⚠️ Azure: Not connected" -ForegroundColor Yellow
        }
    } else {
        Write-Host "⚠️ Azure PowerShell not installed" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Azure check failed" -ForegroundColor Red
}

# 10. SYSTEM HEALTH SUMMARY
Write-Host "`n" + "="*50 -ForegroundColor Cyan
Write-Host "SYSTEM HEALTH SUMMARY" -ForegroundColor Cyan
Write-Host "="*50 -ForegroundColor Cyan

$healthScore = 0
$totalChecks = 8

# Check results
if ($org) { $healthScore++; Write-Host "✅ Tenant Connection" -ForegroundColor Green } else { Write-Host "❌ Tenant Connection" -ForegroundColor Red }
if ($domains | Where-Object IsVerified) { $healthScore++; Write-Host "✅ Domain Verified" -ForegroundColor Green } else { Write-Host "❌ Domain Issues" -ForegroundColor Red }
if ($admin) { $healthScore++; Write-Host "✅ Admin Account" -ForegroundColor Green } else { Write-Host "❌ Admin Account" -ForegroundColor Red }
if ($licenses.Count -gt 0) { $healthScore++; Write-Host "✅ Licensing Active" -ForegroundColor Green } else { Write-Host "❌ No Licenses" -ForegroundColor Red }
if ($groups.Count -gt 0) { $healthScore++; Write-Host "✅ Device Groups" -ForegroundColor Green } else { Write-Host "❌ No Groups" -ForegroundColor Red }
if ($apps.Count -gt 0) { $healthScore++; Write-Host "✅ Applications" -ForegroundColor Green } else { Write-Host "❌ No Apps" -ForegroundColor Red }

try { 
    Get-MgDeviceManagementManagedDevice -ErrorAction Stop | Out-Null
    $healthScore++; Write-Host "✅ Intune Service" -ForegroundColor Green 
} catch { 
    Write-Host "❌ Intune Service (Need EMS E3)" -ForegroundColor Red 
}

try { 
    Get-MgIdentityConditionalAccessPolicy -ErrorAction Stop | Out-Null
    $healthScore++; Write-Host "✅ Conditional Access" -ForegroundColor Green 
} catch { 
    Write-Host "❌ Conditional Access" -ForegroundColor Red 
}

$healthPercent = [math]::Round(($healthScore / $totalChecks) * 100)
Write-Host "`nOVERALL HEALTH: $healthPercent% ($healthScore/$totalChecks)" -ForegroundColor $(if($healthPercent -ge 80){"Green"}elseif($healthPercent -ge 60){"Yellow"}else{"Red"})

# 11. RECOMMENDATIONS
Write-Host "`n" + "="*50 -ForegroundColor Cyan
Write-Host "RECOMMENDATIONS" -ForegroundColor Cyan
Write-Host "="*50 -ForegroundColor Cyan

if ($healthScore -lt $totalChecks) {
    Write-Host "🎯 Priority Actions:" -ForegroundColor Yellow
    
    if ($healthScore -eq 6) {
        Write-Host "1. Purchase EMS E3 license for Intune" -ForegroundColor White
        Write-Host "2. Configure Conditional Access policies" -ForegroundColor White
    }
    
    Write-Host "`n📋 Next Steps:" -ForegroundColor Cyan
    Write-Host "1. Visit: https://admin.microsoft.com/billing/licenses" -ForegroundColor White
    Write-Host "2. Purchase: Enterprise Mobility + Security E3" -ForegroundColor White
    Write-Host "3. Run: .\final-deployment.ps1" -ForegroundColor White
} else {
    Write-Host "🎉 System is fully operational!" -ForegroundColor Green
    Write-Host "✅ All services are healthy and ready" -ForegroundColor Green
}

Write-Host "`n=== System Check Complete ===" -ForegroundColor Cyan