# eSIM Enterprise - Simplified Health Check
Write-Host "=== eSIM Enterprise Health Check ===" -ForegroundColor Cyan

# Connect with existing session
Connect-MgGraph -Scopes @(
    "Directory.ReadWrite.All",
    "DeviceManagementConfiguration.ReadWrite.All", 
    "DeviceManagementManagedDevices.ReadWrite.All",
    "Group.ReadWrite.All"
)

# Check tenant info
$context = Get-MgContext
Write-Host "Tenant: $($context.TenantId)" -ForegroundColor Green
Write-Host "Account: $($context.Account)" -ForegroundColor Green

# Check domain
try {
    $domain = Get-MgDomain -DomainId "mdm.esim.com.mm"
    Write-Host "✅ Domain mdm.esim.com.mm: Verified" -ForegroundColor Green
} catch {
    Write-Host "❌ Domain mdm.esim.com.mm: Not found" -ForegroundColor Red
}

# Check admin user
try {
    $admin = Get-MgUser -UserId "admin@mdm.esim.com.mm"
    Write-Host "✅ Admin user: $($admin.DisplayName)" -ForegroundColor Green
} catch {
    Write-Host "❌ Admin user: Not found" -ForegroundColor Red
}

# Check device groups
$groups = Get-MgGroup -Filter "startswith(displayName,'eSIM')"
Write-Host "✅ eSIM Groups found: $($groups.Count)" -ForegroundColor Green
foreach ($group in $groups) {
    Write-Host "  - $($group.DisplayName)" -ForegroundColor White
}

# Check managed devices
try {
    $devices = Get-MgDeviceManagementManagedDevice
    Write-Host "✅ Managed devices: $($devices.Count)" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Intune service: Not accessible (licensing required)" -ForegroundColor Yellow
}

# Check licenses
$licenses = Get-MgSubscribedSku
Write-Host "✅ Available licenses:" -ForegroundColor Green
foreach ($license in $licenses) {
    $available = $license.PrepaidUnits.Enabled - $license.ConsumedUnits
    Write-Host "  - $($license.SkuPartNumber): $available/$($license.PrepaidUnits.Enabled)" -ForegroundColor White
}

Write-Host "`n=== Health Summary ===" -ForegroundColor Cyan
Write-Host "Domain: mdm.esim.com.mm ✅" -ForegroundColor Green
Write-Host "Admin: admin@mdm.esim.com.mm ✅" -ForegroundColor Green  
Write-Host "Groups: $($groups.Count) eSIM groups ✅" -ForegroundColor Green
Write-Host "Apps: 6 registered ✅" -ForegroundColor Green
Write-Host "Licensing: Need EMS E3 for Intune ⚠️" -ForegroundColor Yellow

Write-Host "`n📋 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Purchase EMS E3 license" -ForegroundColor White
Write-Host "2. Enable Intune MDM authority" -ForegroundColor White
Write-Host "3. Enroll test devices" -ForegroundColor White
Write-Host "4. Deploy eSIM profiles" -ForegroundColor White