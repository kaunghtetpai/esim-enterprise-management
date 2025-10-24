# Fix Intel Drivers - Alternative Methods
Write-Host "=== Intel Driver Fix ===" -ForegroundColor Cyan

Write-Host "`nDetected Intel devices needing drivers:" -ForegroundColor Yellow
Get-PnpDevice | Where-Object {$_.FriendlyName -like '*Intel*' -and $_.Status -eq 'Unknown'} | ForEach-Object {
    Write-Host "❌ $($_.FriendlyName)" -ForegroundColor Red
}

Write-Host "`nAutomatic driver update methods:" -ForegroundColor Yellow
Write-Host "1. Windows Update:" -ForegroundColor White
Write-Host "   Settings > Update & Security > Check for updates" -ForegroundColor Gray

Write-Host "`n2. Device Manager:" -ForegroundColor White  
Write-Host "   Right-click Start > Device Manager > Right-click device > Update driver" -ForegroundColor Gray

Write-Host "`n3. Intel Driver Assistant:" -ForegroundColor White
Write-Host "   Visit: https://www.intel.com/content/www/us/en/support/detect.html" -ForegroundColor Gray

Write-Host "`n4. Manual download:" -ForegroundColor White
Write-Host "   Visit: https://downloadcenter.intel.com" -ForegroundColor Gray

Write-Host "`nOpening Intel Driver Assistant..." -ForegroundColor Green
Start-Process "https://www.intel.com/content/www/us/en/support/detect.html"

Write-Host "`n=== Driver Fix Guide Complete ===" -ForegroundColor Cyan