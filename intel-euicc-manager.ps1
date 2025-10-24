# Intel eUICC Manager Detection and Setup
Write-Host "=== Intel eUICC Manager ===" -ForegroundColor Cyan

# Check for Intel eUICC hardware
Write-Host "`nChecking for Intel eUICC hardware..." -ForegroundColor Yellow
$esimDevices = Get-PnpDevice | Where-Object {
    $_.FriendlyName -like "*eSIM*" -or 
    $_.FriendlyName -like "*eUICC*" -or
    $_.FriendlyName -like "*Intel*" -and $_.Description -like "*SIM*"
}

if ($esimDevices) {
    Write-Host "✅ Intel eUICC devices found:" -ForegroundColor Green
    foreach ($device in $esimDevices) {
        Write-Host "  - $($device.FriendlyName): $($device.Status)" -ForegroundColor White
    }
} else {
    Write-Host "❌ No Intel eUICC hardware detected" -ForegroundColor Red
}

# Check Windows eUICC Manager
Write-Host "`nChecking Windows eUICC Manager..." -ForegroundColor Yellow
try {
    Add-Type -AssemblyName System.Runtime.WindowsRuntime
    $esimManager = [Windows.Networking.NetworkOperators.ESimManager]::Current
    if ($esimManager) {
        Write-Host "✅ Windows eUICC Manager available" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Windows eUICC Manager not available" -ForegroundColor Red
}

# Intel eUICC Manager resources
Write-Host "`nIntel eUICC Manager Resources:" -ForegroundColor Yellow
Write-Host "1. Intel Driver & Support Assistant" -ForegroundColor White
Write-Host "2. Intel Connectivity Performance Suite" -ForegroundColor White
Write-Host "3. Windows Settings > Network & Internet > Cellular" -ForegroundColor White

Write-Host "`nOpening Intel eUICC resources..." -ForegroundColor Green
Start-Process "https://www.intel.com/content/www/us/en/support/articles/000005636/wireless.html"

Write-Host "`n=== eUICC Manager Check Complete ===" -ForegroundColor Cyan