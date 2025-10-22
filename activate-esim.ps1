# Connect to Microsoft Graph
Connect-MgGraph -Scopes "DeviceManagementManagedDevices.ReadWrite.All"

# Get managed device ID (replace with actual device ID)
$deviceId = "YOUR_DEVICE_ID"

# Activate eSIM on device
$uri = "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$deviceId/microsoft.graph.activateDeviceEsim"

try {
    $response = Invoke-MgGraphRequest -Uri $uri -Method POST
    Write-Host "eSIM activation successful" -ForegroundColor Green
    $response
} catch {
    Write-Error "eSIM activation failed: $($_.Exception.Message)"
}