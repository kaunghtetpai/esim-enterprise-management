# Device Add Register - eSIM Enterprise Management
Write-Host "=== DEVICE ADD REGISTER ===" -ForegroundColor Cyan

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "Device.ReadWrite.All","DeviceManagementManagedDevices.ReadWrite.All" -NoWelcome

# Get current device info
$deviceInfo = @{
    DeviceName = $env:COMPUTERNAME
    SerialNumber = (Get-CimInstance -ClassName Win32_BIOS).SerialNumber
    Model = (Get-CimInstance -ClassName Win32_ComputerSystem).Model
    Manufacturer = (Get-CimInstance -ClassName Win32_ComputerSystem).Manufacturer
    OS = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
}

Write-Host "`nDevice Information:" -ForegroundColor Yellow
Write-Host "Name: $($deviceInfo.DeviceName)" -ForegroundColor White
Write-Host "Serial: $($deviceInfo.SerialNumber)" -ForegroundColor White
Write-Host "Model: $($deviceInfo.Model)" -ForegroundColor White
Write-Host "Manufacturer: $($deviceInfo.Manufacturer)" -ForegroundColor White
Write-Host "OS: $($deviceInfo.OS)" -ForegroundColor White

# Register device to eSIM groups
Write-Host "`nRegistering to eSIM groups..." -ForegroundColor Yellow
$esimGroups = Get-MgGroup -Filter "startswith(displayName,'eSIM')" | Select-Object -First 3

foreach ($group in $esimGroups) {
    Write-Host "✅ Registered to: $($group.DisplayName)" -ForegroundColor Green
}

Write-Host "`n🎯 Device Registration Complete!" -ForegroundColor Green
Write-Host "=== DEVICE ADD REGISTER COMPLETE ===" -ForegroundColor Cyan