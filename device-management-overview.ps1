# Device Management Overview for MDM.esim.com.mm
Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All"

$devices = Get-MgDeviceManagementManagedDevice -All
$overview = @{
    Total = $devices.Count
    Compliant = ($devices | Where-Object ComplianceState -eq "compliant").Count
    NonCompliant = ($devices | Where-Object ComplianceState -eq "noncompliant").Count
    Windows = ($devices | Where-Object OperatingSystem -eq "Windows").Count
    iOS = ($devices | Where-Object OperatingSystem -eq "iOS").Count
    Android = ($devices | Where-Object OperatingSystem -eq "Android").Count
}

Write-Host "Device Overview:" -ForegroundColor Cyan
Write-Host "Total: $($overview.Total)" -ForegroundColor White
Write-Host "Compliant: $($overview.Compliant) | Non-Compliant: $($overview.NonCompliant)" -ForegroundColor White
Write-Host "Windows: $($overview.Windows) | iOS: $($overview.iOS) | Android: $($overview.Android)" -ForegroundColor White