# eSIM Enterprise - Complete Error Check and Update
Write-Host "=== eSIM Enterprise Error Check and Update ===" -ForegroundColor Cyan

Connect-MgGraph -Scopes @(
    "Directory.ReadWrite.All",
    "Group.ReadWrite.All",
    "User.ReadWrite.All",
    "Application.ReadWrite.All",
    "DeviceManagementManagedDevices.ReadWrite.All",
    "Organization.ReadWrite.All"
)

# 1. TENANT STATUS CHECK
Write-Host "1. Checking Tenant Status..." -ForegroundColor Yellow
$context = Get-MgContext
$org = Get-MgOrganization
Write-Host "Tenant ID: $($context.TenantId)" -ForegroundColor White
Write-Host "Organization: $($org.DisplayName)" -ForegroundColor White
Write-Host "Account: $($context.Account)" -ForegroundColor White

# 2. DOMAIN VERIFICATION CHECK
Write-Host "`n2. Checking Domain Status..." -ForegroundColor Yellow
$domains = Get-MgDomain
foreach ($domain in $domains) {
    $status = if ($domain.IsVerified) { "VERIFIED" } else { "PENDING" }
    Write-Host "$($domain.Id): $status" -ForegroundColor White
}

# 3. ADMIN ACCOUNT CHECK
Write-Host "`n3. Checking Admin Account..." -ForegroundColor Yellow
try {
    $admin = Get-MgUser -UserId "admin@mdm.esim.com.mm"
    Write-Host "Admin User: $($admin.DisplayName)" -ForegroundColor Green
    Write-Host "UPN: $($admin.UserPrincipalName)" -ForegroundColor White
    Write-Host "Account Enabled: $($admin.AccountEnabled)" -ForegroundColor White
    
    # Check admin roles
    $roles = Get-MgUserMemberOf -UserId $admin.Id | Where-Object { $_."@odata.type" -eq "#microsoft.graph.directoryRole" }
    Write-Host "Assigned Roles: $($roles.Count)" -ForegroundColor White
} catch {
    Write-Host "ERROR: Admin account not found" -ForegroundColor Red
}

# 4. LICENSE STATUS CHECK
Write-Host "`n4. Checking License Status..." -ForegroundColor Yellow
$licenses = Get-MgSubscribedSku
foreach ($license in $licenses) {
    $available = $license.PrepaidUnits.Enabled - $license.ConsumedUnits
    Write-Host "$($license.SkuPartNumber): $available available / $($license.PrepaidUnits.Enabled) total" -ForegroundColor White
}

# Check for Intune licensing
$intuneFound = $licenses | Where-Object { $_.SkuPartNumber -like "*INTUNE*" -or $_.SkuPartNumber -like "*EMS*" }
if ($intuneFound) {
    Write-Host "Intune Licensing: AVAILABLE" -ForegroundColor Green
} else {
    Write-Host "Intune Licensing: NOT FOUND - Need EMS E3" -ForegroundColor Red
}

# 5. DEVICE GROUPS CHECK
Write-Host "`n5. Checking Device Groups..." -ForegroundColor Yellow
$groups = Get-MgGroup -Filter "startswith(displayName,'eSIM')"
Write-Host "eSIM Groups Found: $($groups.Count)" -ForegroundColor White
foreach ($group in $groups) {
    Write-Host "  $($group.DisplayName)" -ForegroundColor Green
}

# 6. APPLICATION REGISTRATIONS CHECK
Write-Host "`n6. Checking Application Registrations..." -ForegroundColor Yellow
$apps = Get-MgApplication -Filter "startswith(displayName,'eSIM')"
Write-Host "eSIM Applications: $($apps.Count)" -ForegroundColor White
foreach ($app in $apps) {
    Write-Host "  $($app.DisplayName): $($app.AppId)" -ForegroundColor Green
}

# 7. INTUNE SERVICE CHECK
Write-Host "`n7. Checking Intune Service..." -ForegroundColor Yellow
try {
    $devices = Get-MgDeviceManagementManagedDevice -ErrorAction Stop
    Write-Host "Intune Service: ACCESSIBLE" -ForegroundColor Green
    Write-Host "Managed Devices: $($devices.Count)" -ForegroundColor White
} catch {
    Write-Host "Intune Service: NOT ACCESSIBLE" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

# 8. CONDITIONAL ACCESS CHECK
Write-Host "`n8. Checking Conditional Access..." -ForegroundColor Yellow
try {
    $caPolicies = Get-MgIdentityConditionalAccessPolicy -ErrorAction Stop
    Write-Host "Conditional Access: ACCESSIBLE" -ForegroundColor Green
    Write-Host "CA Policies: $($caPolicies.Count)" -ForegroundColor White
} catch {
    Write-Host "Conditional Access: ERROR" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

# 9. SYSTEM HEALTH SUMMARY
Write-Host "`n" + "="*60 -ForegroundColor Cyan
Write-Host "SYSTEM HEALTH SUMMARY" -ForegroundColor Cyan
Write-Host "="*60 -ForegroundColor Cyan

$healthChecks = @()
$healthChecks += @{ Name = "Tenant Connection"; Status = if ($org) { "PASS" } else { "FAIL" } }
$healthChecks += @{ Name = "Domain Verification"; Status = if ($domains | Where-Object IsVerified) { "PASS" } else { "FAIL" } }
$healthChecks += @{ Name = "Admin Account"; Status = if ($admin) { "PASS" } else { "FAIL" } }
$healthChecks += @{ Name = "Licensing"; Status = if ($licenses.Count -gt 0) { "PASS" } else { "FAIL" } }
$healthChecks += @{ Name = "Device Groups"; Status = if ($groups.Count -gt 0) { "PASS" } else { "FAIL" } }
$healthChecks += @{ Name = "Applications"; Status = if ($apps.Count -gt 0) { "PASS" } else { "FAIL" } }

try {
    Get-MgDeviceManagementManagedDevice -ErrorAction Stop | Out-Null
    $healthChecks += @{ Name = "Intune Service"; Status = "PASS" }
} catch {
    $healthChecks += @{ Name = "Intune Service"; Status = "FAIL" }
}

try {
    Get-MgIdentityConditionalAccessPolicy -ErrorAction Stop | Out-Null
    $healthChecks += @{ Name = "Conditional Access"; Status = "PASS" }
} catch {
    $healthChecks += @{ Name = "Conditional Access"; Status = "FAIL" }
}

foreach ($check in $healthChecks) {
    $color = if ($check.Status -eq "PASS") { "Green" } else { "Red" }
    Write-Host "$($check.Name): $($check.Status)" -ForegroundColor $color
}

$passCount = ($healthChecks | Where-Object { $_.Status -eq "PASS" }).Count
$totalCount = $healthChecks.Count
$healthPercent = [math]::Round(($passCount / $totalCount) * 100)

Write-Host "`nOVERALL HEALTH: $healthPercent% ($passCount/$totalCount checks passed)" -ForegroundColor $(if($healthPercent -ge 80){"Green"}elseif($healthPercent -ge 60){"Yellow"}else{"Red"})

# 10. ERROR RESOLUTION RECOMMENDATIONS
Write-Host "`n" + "="*60 -ForegroundColor Cyan
Write-Host "ERROR RESOLUTION RECOMMENDATIONS" -ForegroundColor Cyan
Write-Host "="*60 -ForegroundColor Cyan

if ($healthPercent -lt 100) {
    Write-Host "CRITICAL ACTIONS REQUIRED:" -ForegroundColor Red
    
    if (!$intuneFound) {
        Write-Host "1. Purchase EMS E3 license for Intune functionality" -ForegroundColor White
        Write-Host "   URL: https://admin.microsoft.com/billing/licenses" -ForegroundColor Gray
    }
    
    $failedChecks = $healthChecks | Where-Object { $_.Status -eq "FAIL" }
    foreach ($failed in $failedChecks) {
        Write-Host "2. Fix $($failed.Name) configuration" -ForegroundColor White
    }
    
    Write-Host "`nNEXT STEPS:" -ForegroundColor Yellow
    Write-Host "1. Address critical issues above" -ForegroundColor White
    Write-Host "2. Re-run this error check script" -ForegroundColor White
    Write-Host "3. Deploy eSIM portal when health reaches 100%" -ForegroundColor White
} else {
    Write-Host "SYSTEM STATUS: HEALTHY" -ForegroundColor Green
    Write-Host "All systems operational - ready for eSIM portal deployment" -ForegroundColor Green
}

Write-Host "`nError check and update complete." -ForegroundColor Cyan