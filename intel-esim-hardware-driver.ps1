# Intel eUICC/eSIM Hardware Driver Detection and Installation
Write-Host "=== Intel eUICC/eSIM Hardware Driver ===" -ForegroundColor Cyan

# Comprehensive hardware scan
Write-Host "`nScanning for Intel eUICC/eSIM hardware..." -ForegroundColor Yellow
$allDevices = Get-PnpDevice | Where-Object {
    $_.FriendlyName -like "*eUICC*" -or 
    $_.FriendlyName -like "*eSIM*" -or
    $_.FriendlyName -like "*Embedded SIM*" -or
    $_.Description -like "*eUICC*" -or
    $_.Description -like "*eSIM*" -or
    ($_.Class -eq "System" -and $_.Description -like "*SIM*") -or
    ($_.Manufacturer -like "*Intel*" -and $_.Description -like "*Cellular*")
}

if ($allDevices) {
    Write-Host "✅ eUICC/eSIM related devices found:" -ForegroundColor Green
    $allDevices | ForEach-Object {
        Write-Host "  - $($_.FriendlyName): $($_.Status)" -ForegroundColor White
        Write-Host "    Class: $($_.Class), Manufacturer: $($_.Manufacturer)" -ForegroundColor Gray
    }
} else {
    Write-Host "❌ No Intel eUICC/eSIM hardware detected" -ForegroundColor Red
}

# Check for cellular modems
Write-Host "`nChecking for cellular modems..." -ForegroundColor Yellow
$cellularDevices = Get-PnpDevice | Where-Object {
    $_.Class -eq "Net" -and (
        $_.Description -like "*WWAN*" -or
        $_.Description -like "*Mobile*" -or
        $_.Description -like "*Cellular*" -or
        $_.Description -like "*LTE*" -or
        $_.Description -like "*5G*"
    )
}

if ($cellularDevices) {
    Write-Host "✅ Cellular devices found:" -ForegroundColor Green
    $cellularDevices | ForEach-Object {
        Write-Host "  - $($_.FriendlyName): $($_.Status)" -ForegroundColor White
    }
} else {
    Write-Host "❌ No cellular modems detected" -ForegroundColor Red
}

# Intel eUICC driver download links
Write-Host "`nIntel eUICC/eSIM Driver Resources:" -ForegroundColor Yellow
$driverResources = @(
    "https://downloadcenter.intel.com/search?keyword=eUICC+driver",
    "https://downloadcenter.intel.com/search?keyword=eSIM+driver", 
    "https://www.intel.com/content/www/us/en/support/articles/000090426/wireless.html",
    "https://downloadcenter.intel.com/product/59485/Intel-Wireless-Products"
)

Write-Host "Opening Intel driver resources..." -ForegroundColor Green
foreach ($url in $driverResources) {
    Start-Process $url
    Start-Sleep 1
}

Write-Host "`n=== Hardware Driver Scan Complete ===" -ForegroundColor Cyan