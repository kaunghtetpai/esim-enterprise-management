# Fix Intune Licensing for eSIM Portal
# Domain: mdm.esim.com.mm

Write-Host "=== Intune Licensing Setup ===" -ForegroundColor Cyan

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "Directory.ReadWrite.All", "Organization.ReadWrite.All"

# Check available licenses
Write-Host "Checking available licenses..." -ForegroundColor Yellow
$licenses = Get-MgSubscribedSku
$intuneSkus = $licenses | Where-Object { 
    $_.SkuPartNumber -like "*INTUNE*" -or 
    $_.SkuPartNumber -like "*EMS*" -or 
    $_.SkuPartNumber -like "*ENTERPRISE_MOBILITY*" 
}

if ($intuneSkus) {
    Write-Host "Found Intune licenses:" -ForegroundColor Green
    foreach ($sku in $intuneSkus) {
        Write-Host "- $($sku.SkuPartNumber): $($sku.PrepaidUnits.Enabled) available" -ForegroundColor Green
    }
} else {
    Write-Host "No Intune licenses found. Purchase options:" -ForegroundColor Red
    Write-Host "1. Microsoft 365 E3/E5 (includes Intune)" -ForegroundColor Yellow
    Write-Host "2. Enterprise Mobility + Security E3/E5" -ForegroundColor Yellow
    Write-Host "3. Intune standalone license" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Purchase at: https://admin.microsoft.com/AdminPortal/Home#/catalog" -ForegroundColor Cyan
}

# Assign Intune license to admin
$adminUser = "admin@mdm.esim.com.mm"
if ($intuneSkus) {
    $intuneSkuId = $intuneSkus[0].SkuId
    try {
        $licenseAssignment = @{
            addLicenses = @(
                @{
                    skuId = $intuneSkuId
                }
            )
            removeLicenses = @()
        }
        Set-MgUserLicense -UserId $adminUser -BodyParameter $licenseAssignment
        Write-Host "Assigned Intune license to $adminUser" -ForegroundColor Green
    } catch {
        Write-Warning "Failed to assign license: $($_.Exception.Message)"
    }
}

# Enable Intune MDM authority
Write-Host "Configuring Intune MDM authority..." -ForegroundColor Yellow
$mdmAuthority = @{
    mdmAuthority = "intune"
}

try {
    # This would typically be done through the Intune portal
    Write-Host "MDM Authority should be set to Intune in the portal" -ForegroundColor Yellow
    Write-Host "Visit: https://endpoint.microsoft.com > Tenant administration > Connectors and tokens" -ForegroundColor Cyan
} catch {
    Write-Warning "MDM authority configuration requires manual setup in Intune portal"
}

Write-Host "Licensing configuration complete!" -ForegroundColor Green