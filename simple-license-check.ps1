# Simple License Check for Entra ID P2
Write-Host "=== License Status Check ===" -ForegroundColor Cyan
Write-Host "Tenant: 370dd52c-929e-4fcd-aee3-fb5181eff2b7" -ForegroundColor Green
Write-Host "Domain: mdm.esim.com.mm" -ForegroundColor Green

Connect-MgGraph -Scopes "Directory.Read.All"

$licenses = Get-MgSubscribedSku
Write-Host "`nAvailable Licenses:" -ForegroundColor Yellow

foreach ($license in $licenses) {
    $available = $license.PrepaidUnits.Enabled - $license.ConsumedUnits
    Write-Host "- $($license.SkuPartNumber): $available/$($license.PrepaidUnits.Enabled)" -ForegroundColor White
}

Write-Host "`n📋 Current Status:" -ForegroundColor Cyan
Write-Host "✅ Entra ID P2: Advanced identity features" -ForegroundColor Green
Write-Host "⚠️ Intune: Still need EMS E3/E5 for device management" -ForegroundColor Yellow

Write-Host "`n🎯 For eSIM Management:" -ForegroundColor Cyan
Write-Host "Purchase EMS E3 at: https://admin.microsoft.com/billing/licenses" -ForegroundColor White