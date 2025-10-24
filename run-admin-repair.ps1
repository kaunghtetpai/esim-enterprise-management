# Run Admin System Repair
Write-Host "=== ADMIN SYSTEM REPAIR LAUNCHER ===" -ForegroundColor Cyan

Write-Host "`nTo run complete system repair:" -ForegroundColor Yellow
Write-Host "1. Right-click 'admin-system-repair.bat'" -ForegroundColor White
Write-Host "2. Select 'Run as administrator'" -ForegroundColor White
Write-Host "3. Click 'Yes' when prompted" -ForegroundColor White

Write-Host "`nAlternative - Manual commands (as Admin):" -ForegroundColor Yellow
Write-Host "sfc /scannow" -ForegroundColor Green
Write-Host "dism /online /cleanup-image /restorehealth" -ForegroundColor Green
Write-Host "Get-WindowsUpdate -Install -AcceptAll" -ForegroundColor Green

Write-Host "`nOpening admin repair script..." -ForegroundColor Green
Start-Process -FilePath "admin-system-repair.bat" -Verb RunAs -ErrorAction SilentlyContinue

Write-Host "`n=== REPAIR LAUNCHER COMPLETE ===" -ForegroundColor Cyan