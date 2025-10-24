# Enable Intune Service for Entra ID P2 Tenant
# Tenant: 370dd52c-929e-4fcd-aee3-fb5181eff2b7 (mdm.esim.com.mm)

Connect-MgGraph -Scopes "DeviceManagementServiceConfig.ReadWrite.All"

Write-Host "=== Enabling Intune for Entra ID P2 Tenant ===" -ForegroundColor Cyan
Write-Host "Tenant: mdm.esim.com.mm" -ForegroundColor Yellow

# Enable Intune MDM Authority
try {
    $mdmAuthority = @{
        intuneMDMAuthority = "intune"
    }
    Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/beta/organization/370dd52c-929e-4fcd-aee3-fb5181eff2b7" -Method PATCH -Body $mdmAuthority
    Write-Host "+ Intune MDM Authority enabled" -ForegroundColor Green
} catch {
    Write-Host "- MDM Authority error: $($_.Exception.Message)" -ForegroundColor Red
}

# Check Intune service status
try {
    $serviceStatus = Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/beta/deviceManagement" -Method GET
    Write-Host "+ Intune service accessible" -ForegroundColor Green
} catch {
    Write-Host "- Service still initializing, may take 24-48 hours" -ForegroundColor Yellow
}

Write-Host "`nNote: Entra ID P2 includes basic Intune capabilities" -ForegroundColor White
Write-Host "For full device management, consider EMS E3/E5 upgrade" -ForegroundColor White