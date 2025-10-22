# Get all managed devices to find device IDs
Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All"

$devices = Get-MgDeviceManagementManagedDevice -All
$devices | Select-Object Id, DeviceName, UserDisplayName, OperatingSystem | Format-Table