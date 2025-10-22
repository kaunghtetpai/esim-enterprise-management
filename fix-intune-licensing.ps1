# Fix Intune Licensing Issues
Connect-MgGraph -Scopes "Organization.Read.All", "User.ReadWrite.All"

Write-Host "=== Intune Licensing Fix ===" -ForegroundColor Cyan

# Check current licenses
$licenses = Get-MgSubscribedSku
Write-Host "Available Licenses:" -ForegroundColor Yellow
foreach ($license in $licenses) {
    Write-Host "- $($license.SkuPartNumber): $($license.PrepaidUnits.Enabled) total" -ForegroundColor White
}

# Check admin user licensing
$admin = Get-MgUser -UserId "admin@mdm.esim.com.mm" -Property AssignedLicenses,DisplayName
Write-Host "`nAdmin User Licenses: $($admin.AssignedLicenses.Count)" -ForegroundColor White

# Required licenses for Intune
$requiredLicenses = @("INTUNE_A", "EMS", "AAD_PREMIUM", "ENTERPRISEMOBILITY")
Write-Host "`nRequired for full Intune functionality:" -ForegroundColor Yellow
foreach ($req in $requiredLicenses) {
    $found = $licenses | Where-Object { $_.SkuPartNumber -like "*$req*" }
    if ($found) {
        Write-Host "+ $req available" -ForegroundColor Green
    } else {
        Write-Host "- $req missing" -ForegroundColor Red
    }
}

Write-Host "`nRecommendation: Ensure EMS E3/E5 or Intune Plan 1 license is assigned" -ForegroundColor Yellow