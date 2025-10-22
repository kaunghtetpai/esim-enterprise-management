# Microsoft Intune Error Check and Troubleshooting
Write-Host "=== Microsoft Intune Error Check ===" -ForegroundColor Cyan

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "Directory.Read.All", "Organization.Read.All"

# Check 1: Tenant Information
Write-Host "1. Checking Tenant Information..." -ForegroundColor Yellow
$tenant = Get-MgOrganization
Write-Host "Tenant ID: $($tenant.Id)" -ForegroundColor Green
Write-Host "Domain: $($tenant.VerifiedDomains[0].Name)" -ForegroundColor Green

# Check 2: All Available Licenses
Write-Host "`n2. Checking All Available Licenses..." -ForegroundColor Yellow
$allLicenses = Get-MgSubscribedSku
if ($allLicenses) {
    Write-Host "Available License SKUs:" -ForegroundColor Green
    foreach ($license in $allLicenses) {
        $available = $license.PrepaidUnits.Enabled - $license.ConsumedUnits
        Write-Host "- $($license.SkuPartNumber): $available available / $($license.PrepaidUnits.Enabled) total" -ForegroundColor White
    }
} else {
    Write-Host "No licenses found in tenant" -ForegroundColor Red
}

# Check 3: Admin User Status
Write-Host "`n3. Checking Admin User..." -ForegroundColor Yellow
try {
    $admin = Get-MgUser -UserId "admin@mdm.esim.com.mm" -Property DisplayName,UserPrincipalName,AssignedLicenses
    Write-Host "Admin User: $($admin.DisplayName)" -ForegroundColor Green
    Write-Host "UPN: $($admin.UserPrincipalName)" -ForegroundColor Green
    Write-Host "Assigned Licenses: $($admin.AssignedLicenses.Count)" -ForegroundColor Green
} catch {
    Write-Host "Admin user check failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Check 4: Intune Service Status
Write-Host "`n4. Checking Intune Service Status..." -ForegroundColor Yellow
try {
    $intuneService = Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/beta/deviceManagement" -Method GET
    Write-Host "Intune service accessible: Yes" -ForegroundColor Green
} catch {
    Write-Host "Intune service error: $($_.Exception.Message)" -ForegroundColor Red
}

# Check 5: Required Permissions
Write-Host "`n5. Checking Graph Permissions..." -ForegroundColor Yellow
$context = Get-MgContext
Write-Host "Current Scopes: $($context.Scopes -join ', ')" -ForegroundColor White

Write-Host "`n=== Troubleshooting Steps ===" -ForegroundColor Cyan
Write-Host "If no Intune licenses found:" -ForegroundColor Yellow
Write-Host "1. Verify EMS E3 purchase at: https://admin.microsoft.com/billing/licenses" -ForegroundColor White
Write-Host "2. License propagation can take 24-48 hours" -ForegroundColor White
Write-Host "3. Contact Microsoft Support if purchase completed >48h ago" -ForegroundColor White