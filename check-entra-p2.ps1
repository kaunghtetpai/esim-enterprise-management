# Check Entra ID P2 License Status
Write-Host "=== Entra ID P2 License Check ===" -ForegroundColor Cyan
Write-Host "Tenant ID: 370dd52c-929e-4fcd-aee3-fb5181eff2b7" -ForegroundColor Green
Write-Host "Domain: mdm.esim.com.mm" -ForegroundColor Green

Connect-MgGraph -Scopes "Directory.Read.All"

# Check all licenses including Entra ID P2
$licenses = Get-MgSubscribedSku
Write-Host "`nAll Available Licenses:" -ForegroundColor Yellow

foreach ($license in $licenses) {
    $available = $license.PrepaidUnits.Enabled - $license.ConsumedUnits
    Write-Host "- $($license.SkuPartNumber): $available available / $($license.PrepaidUnits.Enabled) total" -ForegroundColor White
    
    # Check if this includes Intune
    if ($license.SkuPartNumber -like "*ENTRA*" -or $license.SkuPartNumber -like "*AAD*" -or $license.SkuPartNumber -like "*EMS*") {
        Write-Host "  └─ Identity and Security License ✅" -ForegroundColor Green
    }
}
}

# Check admin license assignment
$admin = Get-MgUser -UserId "admin@mdm.esim.com.mm" -Property AssignedLicenses,DisplayName
Write-Host "`nAdmin User: $($admin.DisplayName)" -ForegroundColor Green
Write-Host "Assigned Licenses: $($admin.AssignedLicenses.Count)" -ForegroundColor Green

# Note about Intune licensing
Write-Host "`n📋 Note:" -ForegroundColor Cyan
Write-Host "Entra ID P2 provides identity features but requires separate Intune licensing for device management." -ForegroundColor Yellow
Write-Host "For eSIM management, you still need EMS E3/E5 or standalone Intune license." -ForegroundColor Yellow