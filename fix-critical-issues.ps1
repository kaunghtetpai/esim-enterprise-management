# Fix Critical Issues - EMS E3 License Check and Resolution
Write-Host "=== Fixing Critical Issues ===" -ForegroundColor Cyan

Connect-MgGraph -Scopes @(
    "Directory.ReadWrite.All",
    "DeviceManagementManagedDevices.ReadWrite.All",
    "Policy.ReadWrite.ConditionalAccess"
)

# Check if EMS E3 license is now available
Write-Host "1. Checking for EMS E3 License..." -ForegroundColor Yellow
$licenses = Get-MgSubscribedSku
$emsLicense = $licenses | Where-Object { $_.SkuPartNumber -like "*EMS*" -or $_.SkuPartNumber -like "*INTUNE*" }

if ($emsLicense) {
    Write-Host "EMS E3 License Found: $($emsLicense.SkuPartNumber)" -ForegroundColor Green
    
    # Assign license to admin user
    Write-Host "2. Assigning EMS E3 to admin user..." -ForegroundColor Yellow
    try {
        $admin = Get-MgUser -UserId "admin@mdm.esim.com.mm"
        $licenseParams = @{
            AddLicenses = @(
                @{
                    SkuId = $emsLicense.SkuId
                }
            )
            RemoveLicenses = @()
        }
        Set-MgUserLicense -UserId $admin.Id -BodyParameter $licenseParams
        Write-Host "License assigned successfully" -ForegroundColor Green
    } catch {
        Write-Host "License assignment failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Wait for license propagation
    Write-Host "3. Waiting for license propagation (30 seconds)..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30
    
    # Test Intune access
    Write-Host "4. Testing Intune Service..." -ForegroundColor Yellow
    try {
        $devices = Get-MgDeviceManagementManagedDevice -ErrorAction Stop
        Write-Host "Intune Service: ACCESSIBLE" -ForegroundColor Green
    } catch {
        Write-Host "Intune Service: Still not accessible - $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Test Conditional Access
    Write-Host "5. Testing Conditional Access..." -ForegroundColor Yellow
    try {
        $policies = Get-MgIdentityConditionalAccessPolicy -ErrorAction Stop
        Write-Host "Conditional Access: ACCESSIBLE" -ForegroundColor Green
    } catch {
        Write-Host "Conditional Access: Still not accessible - $($_.Exception.Message)" -ForegroundColor Red
    }
    
} else {
    Write-Host "EMS E3 License NOT FOUND" -ForegroundColor Red
    Write-Host "Please purchase EMS E3 license first:" -ForegroundColor Yellow
    Write-Host "1. Go to: https://admin.microsoft.com/billing/licenses" -ForegroundColor White
    Write-Host "2. Search: Enterprise Mobility + Security E3" -ForegroundColor White
    Write-Host "3. Purchase minimum 1 license" -ForegroundColor White
    Write-Host "4. Re-run this script after purchase" -ForegroundColor White
    exit
}

Write-Host "`nCritical issues resolution complete." -ForegroundColor Cyan