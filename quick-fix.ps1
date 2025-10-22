# Quick Fix for eSIM Portal Issues
Write-Host "=== eSIM Portal Quick Fix ===" -ForegroundColor Cyan

# Fix 1: Create groups with mailNickname
Write-Host "Fix 1: Creating device groups with proper mailNickname..." -ForegroundColor Green
& ".\1-setup-intune-tenant.ps1"

# Fix 2: Check and configure licensing
Write-Host "Fix 2: Configuring Intune licensing..." -ForegroundColor Green
& ".\fix-licensing.ps1"

# Fix 3: Manual steps for licensing
Write-Host ""
Write-Host "=== Manual Steps Required ===" -ForegroundColor Yellow
Write-Host "1. Purchase Intune licenses:" -ForegroundColor White
Write-Host "   - Go to: https://admin.microsoft.com" -ForegroundColor Gray
Write-Host "   - Billing > Purchase services" -ForegroundColor Gray
Write-Host "   - Search: 'Enterprise Mobility Security E3'" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Enable Intune MDM:" -ForegroundColor White
Write-Host "   - Go to: https://endpoint.microsoft.com" -ForegroundColor Gray
Write-Host "   - Tenant administration > Connectors and tokens" -ForegroundColor Gray
Write-Host "   - Set MDM authority to Intune" -ForegroundColor Gray
Write-Host ""
Write-Host "3. After licensing, re-run:" -ForegroundColor White
Write-Host "   .\deploy-all.ps1" -ForegroundColor Gray

Write-Host ""
Write-Host "Quick fix complete! Follow manual steps above." -ForegroundColor Green