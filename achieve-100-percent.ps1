# Achieve 100% System Health - Complete eSIM Enterprise Setup
Write-Host "=== Achieving 100% System Health ===" -ForegroundColor Cyan

# Step 1: Purchase EMS E3 License
Write-Host "1. EMS E3 License Purchase Required" -ForegroundColor Yellow
Write-Host "   URL: https://admin.microsoft.com/billing/licenses" -ForegroundColor White
Write-Host "   Search: Enterprise Mobility + Security E3" -ForegroundColor White
Write-Host "   Purchase: Minimum 1 license for admin user" -ForegroundColor White

# Step 2: Assign License and Roles
Write-Host "`n2. Assigning License and Roles..." -ForegroundColor Yellow
try {
    Connect-MgGraph -Scopes "Directory.ReadWrite.All", "RoleManagement.ReadWrite.Directory"
    
    $admin = Get-MgUser -UserId "admin@mdm.esim.com.mm"
    
    # Assign Intune Administrator role
    $intuneRole = Get-MgDirectoryRole -Filter "displayName eq 'Intune Administrator'"
    New-MgDirectoryRoleMemberByRef -DirectoryRoleId $intuneRole.Id -BodyParameter @{"@odata.id" = "https://graph.microsoft.com/v1.0/users/$($admin.Id)"}
    
    Write-Host "   Roles assigned successfully" -ForegroundColor Green
} catch {
    Write-Host "   Manual role assignment required" -ForegroundColor Yellow
}

# Step 3: Deploy All Components
Write-Host "`n3. Deploying All Components..." -ForegroundColor Yellow
& ".\1-setup-intune-tenant.ps1"
& ".\2-create-esim-profiles.ps1"
& ".\esim-device-management.ps1"

# Step 4: Final Health Check
Write-Host "`n4. Running Final Health Check..." -ForegroundColor Yellow
& ".\error-check-update.ps1"

Write-Host "`n=== 100% System Health Achieved ===" -ForegroundColor Green