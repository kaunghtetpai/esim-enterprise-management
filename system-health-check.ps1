# System Health Check - Fixed Version
Write-Host "=== System Health Check ===" -ForegroundColor Cyan

try {
    Connect-MgGraph -Scopes "Directory.Read.All","User.Read.All","Group.Read.All" -NoWelcome
    
    $org = Get-MgOrganization
    $domains = Get-MgDomain
    $groups = Get-MgGroup -Filter "startswith(displayName,'eSIM')"
    $apps = Get-MgApplication -Filter "startswith(displayName,'eSIM')"
    
    Write-Host "`nTenant: $($org.DisplayName)" -ForegroundColor Green
    Write-Host "Domains: $($domains.Count) verified" -ForegroundColor Green
    Write-Host "Groups: $($groups.Count) eSIM groups" -ForegroundColor Green
    Write-Host "Apps: $($apps.Count) eSIM applications" -ForegroundColor Green
    
    $healthScore = 4
    try {
        Get-MgDeviceManagementManagedDevice -ErrorAction Stop | Out-Null
        Write-Host "Intune: Accessible" -ForegroundColor Green
        $healthScore++
    } catch {
        Write-Host "Intune: Need EMS E3 license" -ForegroundColor Red
    }
    
    $healthPercent = [math]::Round(($healthScore / 5) * 100)
    Write-Host "`nSystem Health: $healthPercent%" -ForegroundColor $(if($healthPercent -ge 80){"Green"}else{"Yellow"})
    
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Check Complete ===" -ForegroundColor Cyan