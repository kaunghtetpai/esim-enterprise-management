# Execute Complete Tenant Reset and Rebuild
# Master script for MDM.esim.com.mm clean environment setup

param(
    [switch]$ExecuteReset,
    [switch]$SkipDevices
)

Write-Host "=== COMPLETE TENANT RESET & REBUILD ===" -ForegroundColor Red
Write-Host "Tenant: MDM.esim.com.mm" -ForegroundColor Yellow
Write-Host "This will PERMANENTLY DELETE all configurations!" -ForegroundColor Red

if (!$ExecuteReset) {
    Write-Host "`nTo proceed, run: .\execute-full-reset.ps1 -ExecuteReset" -ForegroundColor Yellow
    Write-Host "Add -SkipDevices to preserve enrolled devices" -ForegroundColor White
    exit
}

$confirm = Read-Host "`nType 'DELETE ALL' to confirm complete reset"
if ($confirm -ne "DELETE ALL") {
    Write-Host "Reset cancelled" -ForegroundColor Green
    exit
}

# Step 1: Reset existing environment
Write-Host "`n=== STEP 1: RESETTING ENVIRONMENT ===" -ForegroundColor Red
if ($SkipDevices) {
    & ".\complete-tenant-reset.ps1" -Confirm -SkipDeviceCleanup
} else {
    & ".\complete-tenant-reset.ps1" -Confirm
}

# Step 2: Rebuild clean environment
Write-Host "`n=== STEP 2: REBUILDING ENVIRONMENT ===" -ForegroundColor Cyan
& ".\rebuild-esim-environment.ps1"

# Step 3: Validate rebuild
Write-Host "`n=== STEP 3: VALIDATING REBUILD ===" -ForegroundColor Green
& ".\validate-rebuild.ps1"

Write-Host "`n=== RESET & REBUILD COMPLETE ===" -ForegroundColor Green
Write-Host "Environment ready for eSIM Profile Management integration" -ForegroundColor White
Write-Host "Next: Configure Company Portal branding and test device enrollment" -ForegroundColor Yellow