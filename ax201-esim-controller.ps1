# Intel AX201 eUICC (eSIM) Controller Detection
Write-Host "=== Intel AX201 eUICC (eSIM) Controller ===" -ForegroundColor Cyan

# Check for Intel AX201 WiFi adapter
Write-Host "`nScanning for Intel AX201..." -ForegroundColor Yellow
$ax201Device = Get-PnpDevice | Where-Object {
    $_.FriendlyName -like "*AX201*" -or
    $_.Description -like "*AX201*" -or
    $_.HardwareID -like "*AX201*"
}

if ($ax201Device) {
    Write-Host "✅ Intel AX201 found:" -ForegroundColor Green
    $ax201Device | ForEach-Object {
        Write-Host "  - $($_.FriendlyName): $($_.Status)" -ForegroundColor White
    }
} else {
    Write-Host "❌ Intel AX201 not detected" -ForegroundColor Red
}

# Check for eUICC capability on AX201
Write-Host "`nChecking AX201 eUICC capability..." -ForegroundColor Yellow
$esimCapable = Get-PnpDevice | Where-Object {
    ($_.FriendlyName -like "*AX201*" -or $_.Description -like "*AX201*") -and
    ($_.FriendlyName -like "*eSIM*" -or $_.Description -like "*eUICC*")
}

if ($esimCapable) {
    Write-Host "✅ AX201 with eUICC support found" -ForegroundColor Green
} else {
    Write-Host "❌ AX201 eUICC capability not detected" -ForegroundColor Red
}

# Intel AX201 eSIM resources
Write-Host "`nIntel AX201 eSIM Resources:" -ForegroundColor Yellow
Write-Host "- AX201 supports eSIM on select platforms" -ForegroundColor White
Write-Host "- Requires OEM implementation and drivers" -ForegroundColor White
Write-Host "- Check manufacturer specifications" -ForegroundColor White

Start-Process "https://www.intel.com/content/www/us/en/products/sku/130293/intel-wifi-6-ax201-gig/specifications.html"

Write-Host "`n=== AX201 eSIM Check Complete ===" -ForegroundColor Cyan