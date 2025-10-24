# Intel AX201 eSIM Enablement Check
Write-Host "=== Intel AX201 eSIM Enablement ===" -ForegroundColor Cyan

# Check AX201 device details
$ax201 = Get-PnpDevice | Where-Object {$_.FriendlyName -like "*AX201*"}
if ($ax201) {
    Write-Host "✅ AX201 Device: $($ax201.FriendlyName)" -ForegroundColor Green
    Write-Host "   Status: $($ax201.Status)" -ForegroundColor White
    Write-Host "   Hardware ID: $($ax201.HardwareID[0])" -ForegroundColor Gray
}

# Check for eSIM registry entries
Write-Host "`nChecking eSIM registry..." -ForegroundColor Yellow
$esimReg = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\WwanSvc" -Name "eUICC" -ErrorAction SilentlyContinue
if ($esimReg) {
    Write-Host "✅ eSIM registry found" -ForegroundColor Green
} else {
    Write-Host "❌ eSIM registry not found" -ForegroundColor Red
}

# Check Windows eSIM service
Write-Host "`nChecking Windows eSIM service..." -ForegroundColor Yellow
try {
    Add-Type -AssemblyName System.Runtime.WindowsRuntime
    $esimManager = [Windows.Networking.NetworkOperators.ESimManager]::Current
    Write-Host "✅ Windows eSIM Manager available" -ForegroundColor Green
} catch {
    Write-Host "❌ Windows eSIM Manager not available" -ForegroundColor Red
}

Write-Host "`nAX201 eSIM Status:" -ForegroundColor Yellow
Write-Host "- Hardware: AX201 chip supports eSIM" -ForegroundColor White
Write-Host "- Implementation: Requires OEM enablement" -ForegroundColor White
Write-Host "- Current status: Not enabled on this device" -ForegroundColor Red

Write-Host "`n=== AX201 eSIM Check Complete ===" -ForegroundColor Cyan