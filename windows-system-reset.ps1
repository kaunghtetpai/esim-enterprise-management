# Windows System Error Check Update Reset
Write-Host "=== Windows System Error Check & Reset ===" -ForegroundColor Cyan

# Basic system check (non-admin)
Write-Host "`n1. Basic System Check..." -ForegroundColor Yellow
$systemInfo = Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion, TotalPhysicalMemory
Write-Host "OS: $($systemInfo.WindowsProductName)" -ForegroundColor White
Write-Host "Version: $($systemInfo.WindowsVersion)" -ForegroundColor White
Write-Host "RAM: $([math]::Round($systemInfo.TotalPhysicalMemory/1GB,2)) GB" -ForegroundColor White

# Check recent errors
Write-Host "`n2. Recent System Errors..." -ForegroundColor Yellow
$errors = Get-EventLog -LogName System -EntryType Error -Newest 5 -ErrorAction SilentlyContinue
if ($errors) {
    Write-Host "Recent errors: $($errors.Count)" -ForegroundColor Red
} else {
    Write-Host "No recent errors found" -ForegroundColor Green
}

# Clear temp files
Write-Host "`n3. Clearing Temp Files..." -ForegroundColor Yellow
Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "✅ Temp files cleared" -ForegroundColor Green

# Reset network
Write-Host "`n4. Network Reset..." -ForegroundColor Yellow
ipconfig /flushdns | Out-Null
Write-Host "✅ DNS cache flushed" -ForegroundColor Green

Write-Host "`nFor full system reset, run as Administrator:" -ForegroundColor Yellow
Write-Host "- sfc /scannow" -ForegroundColor White
Write-Host "- dism /online /cleanup-image /restorehealth" -ForegroundColor White

Write-Host "`n=== System Reset Complete ===" -ForegroundColor Cyan