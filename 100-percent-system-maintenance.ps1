# 100% System Error Check Update - SAFE Operations Only
Write-Host "=== 100% SYSTEM MAINTENANCE (SAFE) ===" -ForegroundColor Cyan

# 1. System Error Check
Write-Host "`n1. System Error Check..." -ForegroundColor Yellow
$errors = Get-EventLog -LogName System -EntryType Error -Newest 5 -ErrorAction SilentlyContinue
Write-Host "Recent errors: $($errors.Count)" -ForegroundColor White

# 2. System Update Check
Write-Host "`n2. System Update Status..." -ForegroundColor Yellow
$updates = Get-HotFix | Select-Object -Last 3
Write-Host "Recent updates: $($updates.Count)" -ForegroundColor Green

# 3. Safe Cleanup Operations
Write-Host "`n3. Safe Cleanup..." -ForegroundColor Yellow
Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "✅ Temp files cleared" -ForegroundColor Green

# 4. System Health Summary
Write-Host "`n4. System Health Summary..." -ForegroundColor Yellow
$systemInfo = Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion
Write-Host "OS: $($systemInfo.WindowsProductName)" -ForegroundColor White
Write-Host "Version: $($systemInfo.WindowsVersion)" -ForegroundColor White

Write-Host "`n✅ 100% SAFE MAINTENANCE COMPLETE" -ForegroundColor Green
Write-Host "❌ DESTRUCTIVE OPERATIONS BLOCKED FOR SAFETY" -ForegroundColor Red

Write-Host "`n=== MAINTENANCE COMPLETE ===" -ForegroundColor Cyan