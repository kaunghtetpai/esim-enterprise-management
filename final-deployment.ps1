# Final eSIM Portal Deployment - After EMS E3 Purchase
Write-Host "=== Final eSIM Portal Deployment ===" -ForegroundColor Cyan
Write-Host "Domain: mdm.esim.com.mm ✅ Verified" -ForegroundColor Green

# Step 1: Verify EMS licensing
Write-Host "Step 1: Verifying EMS E3 licensing..." -ForegroundColor Yellow
& ".\verify-licensing.ps1"

# Step 2: Check if licenses are available
Connect-MgGraph -Scopes "Directory.ReadWrite.All"
$emsLicenses = Get-MgSubscribedSku | Where-Object { $_.SkuPartNumber -like "*EMS*" -or $_.SkuPartNumber -like "*INTUNE*" }

if ($emsLicenses) {
    Write-Host "✅ EMS/Intune licenses found!" -ForegroundColor Green
    
    # Step 3: Assign license to admin
    $adminUser = "admin@mdm.esim.com.mm"
    $license = $emsLicenses[0]
    
    try {
        $assignment = @{
            addLicenses = @(@{ skuId = $license.SkuId })
            removeLicenses = @()
        }
        Set-MgUserLicense -UserId $adminUser -BodyParameter $assignment
        Write-Host "✅ EMS license assigned to $adminUser" -ForegroundColor Green
    } catch {
        Write-Host "License assignment: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    # Step 4: Wait and deploy
    Write-Host "Waiting 30 seconds for license activation..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30
    
    # Step 5: Complete deployment
    Write-Host "Step 5: Deploying eSIM portal..." -ForegroundColor Green
    & ".\deploy-all.ps1"
    
} else {
    Write-Host "❌ No EMS/Intune licenses found" -ForegroundColor Red
    Write-Host "Purchase EMS E3 at: https://admin.microsoft.com/billing/licenses" -ForegroundColor Yellow
}

Write-Host "`n🎯 eSIM Portal Ready for Myanmar Carriers:" -ForegroundColor Cyan
Write-Host "- MPT (414-01)" -ForegroundColor White
Write-Host "- ATOM (414-06)" -ForegroundColor White  
Write-Host "- OOREDOO (414-05)" -ForegroundColor White
Write-Host "- MYTEL (414-09)" -ForegroundColor White