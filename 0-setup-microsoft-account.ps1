# Microsoft 365 Tenant Setup for mdm.esim.com.mm
# Domain: mdm.esim.com.mm
# Admin: admin@mdm.esim.com.mm

Write-Host "=== Microsoft 365 Tenant Setup ===" -ForegroundColor Cyan
Write-Host "Domain: mdm.esim.com.mm" -ForegroundColor Yellow
Write-Host "Admin: admin@mdm.esim.com.mm" -ForegroundColor Yellow

# Connect to Microsoft Graph with tenant admin
Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Green
Connect-MgGraph -TenantId "mdm.esim.com.mm" -Scopes @(
    "Directory.ReadWrite.All",
    "DeviceManagementConfiguration.ReadWrite.All",
    "DeviceManagementManagedDevices.ReadWrite.All",
    "Group.ReadWrite.All",
    "User.ReadWrite.All"
)

# Verify tenant connection
$context = Get-MgContext
Write-Host "Connected to tenant: $($context.TenantId)" -ForegroundColor Green
Write-Host "Account: $($context.Account)" -ForegroundColor Green

# Create admin user if needed
try {
    $adminUser = Get-MgUser -UserId "admin@mdm.esim.com.mm" -ErrorAction SilentlyContinue
    if (!$adminUser) {
        Write-Host "Creating admin user..." -ForegroundColor Yellow
        $newUser = @{
            displayName = "eSIM Portal Administrator"
            userPrincipalName = "admin@mdm.esim.com.mm"
            mailNickname = "admin"
            passwordProfile = @{
                forceChangePasswordNextSignIn = $true
                password = "TempPass123!"
            }
            accountEnabled = $true
        }
        New-MgUser -BodyParameter $newUser
        Write-Host "Admin user created: admin@mdm.esim.com.mm" -ForegroundColor Green
    } else {
        Write-Host "Admin user exists: admin@mdm.esim.com.mm" -ForegroundColor Green
    }
} catch {
    Write-Warning "Admin user setup: $($_.Exception.Message)"
}

# Enable Intune licensing
Write-Host "Configuring Intune licensing..." -ForegroundColor Yellow
$licenses = Get-MgSubscribedSku | Where-Object { $_.SkuPartNumber -like "*INTUNE*" -or $_.SkuPartNumber -like "*EMS*" }
if ($licenses) {
    Write-Host "Intune licenses available: $($licenses.Count)" -ForegroundColor Green
} else {
    Write-Warning "No Intune licenses found. Please purchase EMS E3/E5 or Intune licenses."
}

Write-Host "Microsoft 365 tenant setup complete!" -ForegroundColor Green