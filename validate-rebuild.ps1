# Validate Rebuilt Environment for MDM.esim.com.mm

Connect-MgGraph -Scopes @(
    "DeviceManagementConfiguration.Read.All",
    "Group.Read.All",
    "Policy.Read.All"
)

Write-Host "=== ENVIRONMENT VALIDATION ===" -ForegroundColor Cyan

# Check Groups
Write-Host "`n1. Validating Groups..." -ForegroundColor Yellow
$requiredGroups = @(
    "eSIM Devices - MPT",
    "eSIM Devices - ATOM", 
    "eSIM Devices - U9",
    "eSIM Devices - MYTEL",
    "Admins - eSIM Enterprise",
    "Devices - eSIM"
)

$groupStatus = @{}
foreach ($groupName in $requiredGroups) {
    $group = Get-MgGroup -Filter "displayName eq '$groupName'"
    if ($group) {
        $groupStatus[$groupName] = "EXISTS"
        Write-Host "+ $groupName" -ForegroundColor Green
    } else {
        $groupStatus[$groupName] = "MISSING"
        Write-Host "- $groupName" -ForegroundColor Red
    }
}

# Check Compliance Policies
Write-Host "`n2. Validating Compliance Policies..." -ForegroundColor Yellow
try {
    $policies = Get-MgDeviceManagementDeviceCompliancePolicy -All
    Write-Host "+ Found $($policies.Count) compliance policies" -ForegroundColor Green
    foreach ($policy in $policies) {
        Write-Host "  - $($policy.DisplayName)" -ForegroundColor White
    }
} catch {
    Write-Host "- Compliance policies not accessible" -ForegroundColor Red
}

# Check Conditional Access
Write-Host "`n3. Validating Conditional Access..." -ForegroundColor Yellow
$caPolicies = Get-MgIdentityConditionalAccessPolicy -All
$enabledPolicies = $caPolicies | Where-Object { $_.State -eq "enabled" }
Write-Host "+ Found $($enabledPolicies.Count) enabled CA policies" -ForegroundColor Green

# Generate Summary Report
Write-Host "`n4. Generating Summary..." -ForegroundColor Yellow
$summary = @{
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Tenant = "MDM.esim.com.mm"
    Groups = $groupStatus
    CompliancePolicies = $policies.Count
    ConditionalAccessPolicies = $enabledPolicies.Count
    Status = if ($groupStatus.Values -contains "MISSING") { "INCOMPLETE" } else { "READY" }
}

$reportFile = "C:\IntuneHealthCheck\rebuild-validation-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$summary | ConvertTo-Json -Depth 5 | Out-File -FilePath $reportFile -Encoding UTF8

Write-Host "`n=== VALIDATION COMPLETE ===" -ForegroundColor Cyan
Write-Host "Status: $($summary.Status)" -ForegroundColor $(if($summary.Status -eq "READY"){"Green"}else{"Yellow"})
Write-Host "Report: $reportFile" -ForegroundColor White