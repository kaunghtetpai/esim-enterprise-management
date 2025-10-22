# Get Acer Swift 3 drivers from official sources
Write-Host "=== Acer Swift 3 Driver Guide ===" -ForegroundColor Cyan

# Get system info
$model = (Get-WmiObject -Class Win32_ComputerSystem).Model
$serial = (Get-WmiObject -Class Win32_BIOS).SerialNumber

Write-Host "Model: $model" -ForegroundColor Green
Write-Host "Serial: $serial" -ForegroundColor Green

# Open Acer support page
$acerUrl = "https://www.acer.com/support"
Start-Process $acerUrl

# Check for WWAN/Cellular devices
$wwan = Get-PnpDevice | Where-Object {$_.Class -eq "Net" -and $_.FriendlyName -like "*WWAN*"}
if ($wwan) {
    Write-Host "WWAN device found: $($wwan.FriendlyName)" -ForegroundColor Green
} else {
    Write-Host "No WWAN/Cellular modem detected" -ForegroundColor Yellow
}

Write-Host "`nManual driver sources:" -ForegroundColor Cyan
Write-Host "1. Acer Support: support.acer.com"
Write-Host "2. Intel: downloadcenter.intel.com"
Write-Host "3. Device Manager > Update Driver"