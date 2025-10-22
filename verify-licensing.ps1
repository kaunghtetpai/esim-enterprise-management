# Verify Intune Licensing Status
Write-Host "=== Verifying Intune Licensing ===" -ForegroundColor Cyan

Connect-MgGraph -Scopes "Directory.Read.All"

# Check licenses
$licenses = Get-MgSubscribedSku | Where-Object { 
    $_.SkuPartNumber -like "*INTUNE*" -or 
    $_.SkuPartNumber -like "*EMS*" -or 
    $_.SkuPartNumber -like "*ENTERPRISE_MOBILITY*" 
}

if ($licenses) {
    Write-Host "✅ Intune licenses found!" -ForegroundColor Green
    foreach ($sku in $licenses) {
        Write-Host "- $($sku.SkuPartNumber): $($sku.PrepaidUnits.Enabled) licenses" -ForegroundColor Green
    }
    
    # Check admin license assignment
    $admin = Get-MgUser -UserId "admin@mdm.esim.com.mm" -Property AssignedLicenses
    $hasIntune = $admin.AssignedLicenses | Where-Object { $_.SkuId -in $licenses.SkuId }
    
    if ($hasIntune) {
        Write-Host "✅ Admin has Intune license assigned" -ForegroundColor Green
        Write-Host "Ready to deploy eSIM portal!" -ForegroundColor Cyan
    } else {
        Write-Host "⚠️ Assign Intune license to admin@mdm.esim.com.mm" -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ No Intune licenses found" -ForegroundColor Red
    Write-Host "Complete licensing purchase first" -ForegroundColor Yellow
}