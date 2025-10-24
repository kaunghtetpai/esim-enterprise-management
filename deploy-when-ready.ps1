# Deploy eSIM Portal When System Health Reaches 100%
Write-Host "=== eSIM Portal Deployment Check ===" -ForegroundColor Cyan

# Run error check first
Write-Host "1. Running system health check..." -ForegroundColor Yellow
& ".\error-check-update.ps1"

# Check if system is ready
Connect-MgGraph -Scopes @(
    "Directory.ReadWrite.All",
    "DeviceManagementManagedDevices.ReadWrite.All",
    "Policy.ReadWrite.ConditionalAccess"
)

$healthChecks = @()
try {
    $org = Get-MgOrganization
    $healthChecks += @{ Name = "Tenant"; Status = if ($org) { "PASS" } else { "FAIL" } }
    
    $domains = Get-MgDomain | Where-Object IsVerified
    $healthChecks += @{ Name = "Domains"; Status = if ($domains) { "PASS" } else { "FAIL" } }
    
    $admin = Get-MgUser -UserId "admin@mdm.esim.com.mm"
    $healthChecks += @{ Name = "Admin"; Status = if ($admin) { "PASS" } else { "FAIL" } }
    
    $groups = Get-MgGroup -Filter "startswith(displayName,'eSIM')"
    $healthChecks += @{ Name = "Groups"; Status = if ($groups.Count -gt 0) { "PASS" } else { "FAIL" } }
    
    $apps = Get-MgApplication -Filter "startswith(displayName,'eSIM')"
    $healthChecks += @{ Name = "Apps"; Status = if ($apps.Count -gt 0) { "PASS" } else { "FAIL" } }
    
    Get-MgDeviceManagementManagedDevice -ErrorAction Stop | Out-Null
    $healthChecks += @{ Name = "Intune"; Status = "PASS" }
    
    Get-MgIdentityConditionalAccessPolicy -ErrorAction Stop | Out-Null
    $healthChecks += @{ Name = "ConditionalAccess"; Status = "PASS" }
    
} catch {
    $healthChecks += @{ Name = "Intune"; Status = "FAIL" }
    $healthChecks += @{ Name = "ConditionalAccess"; Status = "FAIL" }
}

$passCount = ($healthChecks | Where-Object { $_.Status -eq "PASS" }).Count
$totalCount = $healthChecks.Count
$healthPercent = [math]::Round(($passCount / $totalCount) * 100)

Write-Host "`nSystem Health: $healthPercent% ($passCount/$totalCount)" -ForegroundColor $(if($healthPercent -eq 100){"Green"}else{"Yellow"})

if ($healthPercent -eq 100) {
    Write-Host "`nSYSTEM READY - Deploying eSIM Portal..." -ForegroundColor Green
    
    # Deploy eSIM profiles
    Write-Host "2. Creating eSIM profiles..." -ForegroundColor Yellow
    & ".\2-create-esim-profiles.ps1"
    
    # Run final deployment
    Write-Host "3. Running final deployment..." -ForegroundColor Yellow
    & ".\final-deployment.ps1"
    
    Write-Host "`neSIM Portal deployment complete!" -ForegroundColor Green
    
} else {
    Write-Host "`nSYSTEM NOT READY - Health must be 100%" -ForegroundColor Red
    Write-Host "Failed checks:" -ForegroundColor Yellow
    $healthChecks | Where-Object { $_.Status -eq "FAIL" } | ForEach-Object {
        Write-Host "  $($_.Name): FAIL" -ForegroundColor Red
    }
    Write-Host "`nRun fix-critical-issues.ps1 first" -ForegroundColor Yellow
}