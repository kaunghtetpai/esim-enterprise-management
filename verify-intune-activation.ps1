# Verify Intune Activation Status
Connect-MgGraph -Scopes "DeviceManagementServiceConfig.Read.All"

Write-Host "=== Verifying Intune Activation ===" -ForegroundColor Cyan

# Test Intune service access
try {
    $service = Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/beta/deviceManagement" -Method GET
    Write-Host "+ Intune service is active" -ForegroundColor Green
    
    # Test device management endpoints
    $configs = Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations" -Method GET
    Write-Host "+ Device configurations accessible" -ForegroundColor Green
    
    $compliance = Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/beta/deviceManagement/deviceCompliancePolicies" -Method GET
    Write-Host "+ Compliance policies accessible" -ForegroundColor Green
    
    Write-Host "`nIntune is fully activated and ready!" -ForegroundColor Green
    Write-Host "You can now run: .\run-health-check.ps1 -Full" -ForegroundColor White
    
} catch {
    Write-Host "- Intune not yet activated" -ForegroundColor Red
    Write-Host "Please complete manual activation at https://intune.microsoft.com" -ForegroundColor Yellow
}