# Complete eSIM Enterprise Management Portal Deployment
# Admin: admin@mdm.esim.com.mm

Write-Host "=== eSIM Enterprise Management Portal Deployment ===" -ForegroundColor Cyan
Write-Host "Starting deployment for Myanmar carriers: MPT, ATOM, OOREDOO, MYTEL" -ForegroundColor Yellow

# Check prerequisites
if (!(Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Write-Host "Installing Microsoft Graph PowerShell..." -ForegroundColor Yellow
    Install-Module Microsoft.Graph -Scope CurrentUser -Force
}

# Step 0: Setup Microsoft 365 tenant
Write-Host "Step 0: Setting up Microsoft 365 tenant..." -ForegroundColor Green
& ".\0-setup-microsoft-account.ps1"

# Step 1: Setup tenant and groups
Write-Host "Step 1: Setting up tenant and device groups..." -ForegroundColor Green
& ".\1-setup-intune-tenant.ps1"

# Step 2: Create eSIM profiles
Write-Host "Step 2: Creating eSIM profiles for carriers..." -ForegroundColor Green
& ".\2-create-esim-profiles.ps1"

# Step 3: Configure compliance policies
Write-Host "Step 3: Configuring compliance policies..." -ForegroundColor Green
& ".\3-compliance-policies.ps1"

# Step 4: Import automation modules
Write-Host "Step 4: Setting up automation..." -ForegroundColor Green
Import-Module ".\4-automation-scripts.ps1" -Force
Import-Module ".\5-monitoring-dashboard.ps1" -Force

# Step 5: Show initial dashboard
Write-Host "Step 5: Displaying eSIM dashboard..." -ForegroundColor Green
Show-eSIMDashboard

Write-Host ""
Write-Host "=== Deployment Complete ===" -ForegroundColor Green
Write-Host "eSIM Enterprise Management Portal is ready!" -ForegroundColor Cyan
Write-Host "Admin Portal: https://endpoint.microsoft.com" -ForegroundColor Yellow
Write-Host "Admin Account: admin@mdm.esim.com.mm" -ForegroundColor Yellow
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor White
Write-Host "1. Enroll devices in Intune" -ForegroundColor Gray
Write-Host "2. Assign eSIM profiles to device groups" -ForegroundColor Gray
Write-Host "3. Monitor compliance and deployment status" -ForegroundColor Gray
Write-Host "4. Use automation scripts for bulk operations" -ForegroundColor Gray