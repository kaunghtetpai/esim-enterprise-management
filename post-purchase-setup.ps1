# Post-Purchase Intune Setup
Write-Host "=== Post-Purchase Intune Configuration ===" -ForegroundColor Cyan

# Step 1: Verify licensing
Write-Host "Step 1: Verifying EMS E3 licensing..." -ForegroundColor Green
& ".\verify-licensing.ps1"

# Step 2: Assign licenses to admin
Connect-MgGraph -Scopes "User.ReadWrite.All", "Directory.ReadWrite.All"

$licenses = Get-MgSubscribedSku | Where-Object { $_.SkuPartNumber -like "*EMS*" }
if ($licenses) {
    $emsLicense = $licenses[0]
    $assignment = @{
        addLicenses = @(@{ skuId = $emsLicense.SkuId })
        removeLicenses = @()
    }
    
    try {
        Set-MgUserLicense -UserId "admin@mdm.esim.com.mm" -BodyParameter $assignment
        Write-Host "✅ EMS license assigned to admin" -ForegroundColor Green
    } catch {
        Write-Host "⚠️ License assignment: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# Step 3: Wait for license propagation
Write-Host "Waiting 60 seconds for license propagation..." -ForegroundColor Yellow
Start-Sleep -Seconds 60

# Step 4: Complete eSIM portal deployment
Write-Host "Step 4: Deploying complete eSIM portal..." -ForegroundColor Green
& ".\deploy-all.ps1"

Write-Host "✅ eSIM Enterprise Management Portal deployment complete!" -ForegroundColor Green